local HADES_TOOLS = {Version = 2}
-- Session data belongs to the Lua registry, which the game's global save scan excludes.
local registry = debug.getregistry()
local session = registry["HADES_TOOLS.RuntimeSession"]
if session == nil then
    session = {}
    registry["HADES_TOOLS.RuntimeSession"] = session
end
assert(type(session) == "table", "HADES_TOOLS session registry entry is invalid")

local function hero()
    assert(CurrentRun and CurrentRun.Hero, "A hero must be loaded")
    return CurrentRun.Hero
end

local function number(value, min, max)
    assert(type(value) == "number" and value == value and value >= min and value <= max, "Number is outside allowed range")
    return value
end

local function scalarFields(value)
    local result = {}
    if type(value) ~= "table" then return result end
    for key,item in pairs(value) do
        if type(key) == "string" and (type(item) == "number" or type(item) == "string" or type(item) == "boolean") then
            result[key] = item
        end
    end
    return result
end

local function traits(h)
    local result = {}
    local entries = {}
    for _,t in pairs(h.Traits or {}) do
        if t.Name and entries[t.Name] == nil then entries[t.Name] = t end
    end
    for name,t in pairs(entries) do
        local data = TraitData[name]
        table.insert(result,{name=name,rarity=t.Rarity,level=GetTraitCount(h,t),stackNum=t.StackNum,slot=t.Slot,
            description=data and data.Description,fields=scalarFields(t)})
    end
    table.sort(result,function(a,b)return tostring(a.name)<tostring(b.name)end)
    return result
end

local function weaponState(h)
    local result = {available=false,entries={}}
    if type(h.Weapons) ~= "table" then return result end
    result.available = true
    for key,item in pairs(h.Weapons) do
        if type(key) == "string" then
            table.insert(result.entries,{key=key,fields=scalarFields(item)})
        end
    end
    table.sort(result.entries,function(a,b)return a.key<b.key end)
    return result
end

local function findTrait(h,name)
    for _,item in pairs(h.Traits or {}) do
        if type(item) == "table" and item.Name == name then return item end
    end
    return nil
end

local function setInfiniteCast(h, enabled)
    local currentMax = GetWeaponMaxAmmo({Id=h.ObjectId, WeaponName="RangedWeapon"})
    local currentAmmo = GetWeaponProperty({Id=h.ObjectId, WeaponName="RangedWeapon", Property="Ammo"})
    assert(type(currentMax) == "number" and type(currentAmmo) == "number", "RangedWeapon ammo properties are unavailable")
    if enabled then
        if not session.infiniteCast then
            session.infiniteCastOriginal = {maxAmmo=currentMax, ammo=currentAmmo}
        end
        SetWeaponProperty({WeaponName="RangedWeapon", DestinationId=h.ObjectId, Property="MaxAmmo", Value=999})
        RunWeaponMethod({Id=h.ObjectId, Weapon="RangedWeapon", Method="RefillAmmo"})
        session.infiniteCast = true
    else
        local original = session.infiniteCastOriginal
        if original then
            SetWeaponProperty({WeaponName="RangedWeapon", DestinationId=h.ObjectId, Property="MaxAmmo", Value=original.maxAmmo})
            RunWeaponMethod({Id=h.ObjectId, Weapon="RangedWeapon", Method="EmptyAmmo"})
            if original.ammo > 0 then
                RunWeaponMethod({Id=h.ObjectId, Weapon="RangedWeapon", Method="AddAmmo", Parameters={math.min(original.ammo, original.maxAmmo)}})
            end
        else
            RunWeaponMethod({Id=h.ObjectId, Weapon="RangedWeapon", Method="RefillAmmo"})
        end
        session.infiniteCast = false
        session.infiniteCastOriginal = nil
    end
end

local function maintainInfiniteCast(h)
    if session.infiniteCast then
        RunWeaponMethod({Id=h.ObjectId, Weapon="RangedWeapon", Method="RefillAmmo"})
    end
end

local RAGEBOT_WEAPONS = {
    GunWeapon = {
        kind = "gun",
        ammoWeapon = "GunWeapon",
        linked = {"GunWeapon", "GunWeaponDash", "SniperGunWeapon", "SniperGunWeaponDash"}
    },
    BowWeapon = {
        kind = "bow",
        linked = {"BowWeapon", "BowWeaponDash"}
    }
}

local RAGEBOT_ACCURACY_PROPERTIES = {
    "Spread", "Scatter", "ScatterCap",
    "ProjectileAngleOffset", "ProjectileAngleOffsetMin", "ProjectileAngleOffsetMax"
}
local RAGEBOT_MOVEMENT_PROPERTIES = {
    "RootOwnerWhileFiring", "BlockMoveInput", "CancelMovement", "ChargeCancelMovement",
    "CanCancelDisables", "CanCancelOwnDisables"
}
local RAGEBOT_MOVEMENT_EFFECTS = {
    GunWeapon = {"GunDisable", "GunDisableCancellable", "GunSelfSpeed", "GunSelfHalt"},
    GunWeaponDash = {"GunDisable", "GunDisableCancellable", "GunSelfSpeed", "GunSelfHalt"},
    BowWeapon = {"BowWeaponDisable", "BowWeaponDisableCancelable", "BowSelfSpeed", "BowSelfHalt"},
    BowWeaponDash = {"BowWeaponDisable", "BowWeaponDisableCancelable", "BowSelfSpeed", "BowSelfHalt"}
}
local RAGEBOT_TARGET_PRIORITIES = {nearest=true, lowest_health=true, elite=true, boss=true}
local RAGEBOT_SPREAD_MODES = {off=true, seed_check=true, remove_spread=true}

local function ragebotSettings()
    if type(session.ragebot) ~= "table" then session.ragebot = {} end
    local settings = session.ragebot
    settings.autoAim = settings.autoAim == true
    settings.autoFire = settings.autoFire == true
    settings.silentShot = settings.silentShot == true
    settings.lockHold = settings.lockHold ~= false
    settings.syncWeapons = settings.syncWeapons ~= false
    settings.perfectBow = settings.perfectBow ~= false
    settings.targetPriority = RAGEBOT_TARGET_PRIORITIES[settings.targetPriority] and settings.targetPriority or "nearest"
    settings.spreadMode = RAGEBOT_SPREAD_MODES[settings.spreadMode] and settings.spreadMode or "remove_spread"
    settings.generation = type(settings.generation) == "number" and settings.generation or 0
    settings.targetId = type(settings.targetId) == "number" and settings.targetId or 0
    return settings
end

local function ragebotEnabled(settings)
    return settings.autoAim or settings.autoFire or settings.silentShot
end

local function ragebotWeapon()
    local weapon = GetEquippedWeapon()
    return weapon, RAGEBOT_WEAPONS[weapon]
end

local function clearRagebotTargeting()
    local applied = session.ragebotApplied
    if type(applied) ~= "table" then return end
    if IsAlive({Id=applied.heroObjectId}) then
        for weaponName,properties in pairs(applied.weapons) do
            SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                Property="OverrideFireRequestTarget",Value=-1,DataValue=false})
            SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                Property="AutoLock",Value=properties.autoLock})
            SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                Property="AutoLockWithMouse",Value=properties.autoLockWithMouse})
            SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                Property="AutoLockArcDistance",Value=properties.autoLockArcDistance})
            SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                Property="UseTargetAngle",Value=properties.useTargetAngle})
            SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                Property="SetCompleteAngleOnFire",Value=properties.setCompleteAngleOnFire})
            SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                Property="SetCompleteAngleOnCharge",Value=properties.setCompleteAngleOnCharge})
            for property,value in pairs(properties.accuracy) do
                SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                    Property=property,Value=value})
            end
            for property,value in pairs(properties.movement or {}) do
                SetWeaponProperty({WeaponName=weaponName,DestinationId=applied.heroObjectId,
                    Property=property,Value=value})
            end
        end
    end
    session.ragebotApplied = nil
end

local function ragebotLinkedWeapons(weapon, family, settings)
    if settings.syncWeapons then return family.linked end
    return {weapon}
end

local function prepareRagebotTargeting(h, weapon, family, settings)
    local applied = session.ragebotApplied
    if applied and (applied.heroObjectId ~= h.ObjectId or applied.weapon ~= weapon or applied.syncWeapons ~= settings.syncWeapons) then
        clearRagebotTargeting()
        applied = nil
    end
    if applied then return applied end

    applied = {heroObjectId=h.ObjectId,weapon=weapon,syncWeapons=settings.syncWeapons,weapons={}}
    for _,weaponName in ipairs(ragebotLinkedWeapons(weapon, family, settings)) do
        local autoLock = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property="AutoLock"})
        local autoLockWithMouse = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property="AutoLockWithMouse"})
        local autoLockArcDistance = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property="AutoLockArcDistance"})
        local useTargetAngle = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property="UseTargetAngle"}) == true
        local fireAngle = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property="SetCompleteAngleOnFire"})
        local chargeAngle = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property="SetCompleteAngleOnCharge"})
        assert(type(autoLock) == "boolean" and type(autoLockWithMouse) == "boolean" and
            type(autoLockArcDistance) == "number" and type(fireAngle) == "boolean" and
            type(chargeAngle) == "boolean", "Ragebot targeting properties are unavailable for "..weaponName)
        local accuracy = {}
        for _,property in ipairs(RAGEBOT_ACCURACY_PROPERTIES) do
            local value = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property=property})
            if type(value) == "number" then accuracy[property] = value end
        end
        applied.weapons[weaponName] = {
            autoLock=autoLock,
            autoLockWithMouse=autoLockWithMouse,
            autoLockArcDistance=autoLockArcDistance,
            useTargetAngle=useTargetAngle,
            setCompleteAngleOnFire=fireAngle,
            setCompleteAngleOnCharge=chargeAngle,
            accuracy=accuracy
        }
        applied.weapons[weaponName].movement = {}
        for _,property in ipairs(RAGEBOT_MOVEMENT_PROPERTIES) do
            local value = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property=property})
            if type(value) == "boolean" then applied.weapons[weaponName].movement[property] = value end
        end
        applied.weapons[weaponName].movementEffects = RAGEBOT_MOVEMENT_EFFECTS[weaponName] or {}
    end
    session.ragebotApplied = applied
    return applied
end

local validateRagebotTarget

local function clearRagebotMovementEffects(h, applied, settings)
    if settings.spreadMode ~= "remove_spread" then return end
    for _,properties in pairs(applied.weapons or {}) do
        for _,effectName in ipairs(properties.movementEffects or {}) do
            ClearEffect({Id=h.ObjectId,Name=effectName})
        end
    end
end

local function acquireRagebotTarget(h, weaponRange)
    -- GetClosest can keep returning an enemy during its death animation.  Ask
    -- the engine for an ordered candidate set and validate every entry in the
    -- same frame, so the next live target is selected without waiting for the
    -- stale object to disappear from EnemyTeam.
    local candidates = GetClosestIds({Id=h.ObjectId,DestinationName="EnemyTeam",
        IgnoreInvulnerable=true,IgnoreHomingIneligible=true,Distance=weaponRange,
        MaximumCount=32})
    assert(type(candidates) == "table", "Ragebot target query returned an invalid candidate list")
    local validCandidates = {}
    local priority = ragebotSettings().targetPriority
    for _,candidateId in ipairs(candidates) do
        local valid,distance = validateRagebotTarget(h, candidateId, weaponRange)
        if valid then
            if priority == "nearest" then return candidateId end
            local enemy = ActiveEnemies and ActiveEnemies[candidateId]
            local health = enemy and enemy.Health
            local maxHealth = enemy and enemy.MaxHealth
            assert(enemy == nil or (type(health) == "number" and type(maxHealth) == "number"),
                "Ragebot enemy health data is unavailable")
            table.insert(validCandidates, {id=candidateId,distance=distance,enemy=enemy,
                healthRatio=(maxHealth and maxHealth > 0) and health / maxHealth or math.huge})
        end
    end
    table.sort(validCandidates, function(a,b)
        if priority == "lowest_health" and a.healthRatio ~= b.healthRatio then return a.healthRatio < b.healthRatio end
        if priority == "elite" or priority == "boss" then
            local field = priority == "elite" and "IsElite" or "IsBoss"
            local ae = a.enemy and a.enemy[field] == true
            local be = b.enemy and b.enemy[field] == true
            if ae ~= be then return ae end
        end
        return a.distance < b.distance
    end)
    if validCandidates[1] then return validCandidates[1].id end
    return 0
end

validateRagebotTarget = function(h, targetId, weaponRange)
    if type(targetId) ~= "number" or targetId <= 0 or not IsAlive({Id=targetId}) or
        IsInvulnerable({Id=targetId}) then
        return false, 0
    end
    local distance = GetDistance({Id=h.ObjectId,DestinationId=targetId})
    if type(distance) ~= "number" then return false, 0 end
    if distance > weaponRange then return false, distance end
    if not HasLineOfSight({Id=h.ObjectId,DestinationId=targetId,StopsProjectiles=true}) then
        return false, distance
    end
    return true, distance
end

local function applyRagebotTarget(h, weapon, family, targetId, silentShot, settings)
    local applied = prepareRagebotTargeting(h, weapon, family, settings)
    for weaponName,properties in pairs(applied.weapons) do
        local fireAngle = properties.setCompleteAngleOnFire
        local chargeAngle = properties.setCompleteAngleOnCharge
        if silentShot then
            fireAngle = false
            chargeAngle = false
        end
        SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
            Property="OverrideFireRequestTarget",Value=targetId,DataValue=false})
        SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
            Property="AutoLock",Value=true})
        SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
            Property="AutoLockWithMouse",Value=true})
        SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
            Property="AutoLockArcDistance",Value=math.rad(360)})
        SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
            Property="UseTargetAngle",Value=true})
        SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
            Property="SetCompleteAngleOnFire",Value=fireAngle})
        SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
            Property="SetCompleteAngleOnCharge",Value=chargeAngle})
        for _,property in ipairs(RAGEBOT_ACCURACY_PROPERTIES) do
            local current = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weaponName,Property=property})
            if type(current) == "number" then
                if properties.accuracy[property] == nil or current ~= 0 then
                    properties.accuracy[property] = current
                end
                local value = properties.accuracy[property]
                if settings.spreadMode == "remove_spread" then
                    value = 0
                elseif settings.spreadMode == "seed_check" then
                    value = 0
                    if property == "ProjectileAngleOffset" then value = properties.accuracy[property] end
                end
                SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
                    Property=property,Value=value})
            end
        end
        for property,value in pairs(properties.movement) do
            local appliedValue = value
            if settings.spreadMode == "remove_spread" then
                if property == "RootOwnerWhileFiring" or property == "BlockMoveInput" or
                    property == "CancelMovement" or property == "ChargeCancelMovement" then
                    appliedValue = false
                elseif property == "CanCancelDisables" or property == "CanCancelOwnDisables" then
                    appliedValue = true
                end
            end
            SetWeaponProperty({WeaponName=weaponName,DestinationId=h.ObjectId,
                Property=property,Value=appliedValue})
        end
    end
    clearRagebotMovementEffects(h, applied, settings)
end

local function ragebotWeaponReady(h, weapon, family, settings)
    if not CanAttack({Id=h.ObjectId}) then return false end
    if family.kind == "gun" then
        if h.Reloading then return false end
        local maxAmmo = GetWeaponMaxAmmo({Id=h.ObjectId,WeaponName=family.ammoWeapon})
        assert(type(maxAmmo) == "number", "Ragebot gun max ammo is unavailable")
        -- GunInfiniteAmmoTrait uses MaxAmmo = -1.  In that mode Ammo is not a
        -- consumable counter and the engine's CanAttack result is authoritative.
        if maxAmmo < 0 then return true end
        local ammo = GetWeaponProperty({Id=h.ObjectId,WeaponName=family.ammoWeapon,Property="Ammo"})
        assert(type(ammo) == "number", "Ragebot gun ammo is unavailable")
        return ammo > 0
    end
    assert(family.kind == "bow", "Unknown Ragebot weapon family")
    for _,weaponName in ipairs(family.linked) do
        if GetWeaponProperty({Id=h.ObjectId,WeaponName=weaponName,Property="Charging"}) then
            return false
        end
    end
    if settings.perfectBow then
        local perfect = GetWeaponProperty({Id=h.ObjectId,WeaponName=weapon,Property="PerfectCharge"})
        assert(type(perfect) == "boolean", "Ragebot bow perfect-charge state is unavailable")
        if not perfect then return false end
    end
    return true
end

local function fireRagebotWeapon(h, weapon, family, targetId, settings)
    if not ragebotWeaponReady(h, weapon, family, settings) then return false end
    local valid = validateRagebotTarget(h, targetId,
        GetWeaponDataValue({Id=h.ObjectId,WeaponName=weapon,Property="AutoLockRange"}))
    if not valid then return false end
    local shotAngleDegrees = GetAngleBetween({Id=h.ObjectId,DestinationId=targetId})
    if type(shotAngleDegrees) ~= "number" then return false end
    FireWeaponFromUnit({Weapon=weapon,Id=h.ObjectId,DestinationId=targetId,
        Angle=math.rad(shotAngleDegrees)})
    clearRagebotMovementEffects(h, session.ragebotApplied or {}, settings)
    return true
end

local function ragebotLoop(generation)
    local settings = ragebotSettings()
    while settings.generation == generation and ragebotEnabled(settings) do
        local h = CurrentRun and CurrentRun.Hero
        if h and not h.IsDead then
            local weapon,family = ragebotWeapon()
            if family then
                local weaponRange = GetWeaponDataValue({Id=h.ObjectId,WeaponName=weapon,Property="AutoLockRange"})
                assert(type(weaponRange) == "number" and weaponRange > 0,
                    "Ragebot weapon range is unavailable for "..weapon)
                local targetId = settings.lockHold and settings.targetId or 0
                local valid,targetDistance = validateRagebotTarget(h, targetId, weaponRange)
                if not valid then
                    targetId = acquireRagebotTarget(h, weaponRange)
                    valid,targetDistance = validateRagebotTarget(h, targetId, weaponRange)
                    if not valid then targetId,targetDistance = 0,0 end
                end
                settings.weapon = weapon
                settings.supported = true
                settings.targetId = targetId
                settings.range = weaponRange
                settings.targetDistance = targetDistance

                if targetId > 0 then
                    applyRagebotTarget(h, weapon, family, targetId, settings.silentShot, settings)
                else
                    clearRagebotTargeting()
                end

                if targetId > 0 and settings.autoAim and not settings.silentShot then
                    AngleTowardTarget({Id=h.ObjectId,DestinationId=targetId})
                end

                if targetId > 0 and settings.autoFire then
                    fireRagebotWeapon(h, weapon, family, targetId, settings)
                end
            else
                clearRagebotTargeting()
                settings.weapon = weapon
                settings.supported = false
                settings.targetId = 0
                settings.range = 0
                settings.targetDistance = 0
            end
        else
            clearRagebotTargeting()
            settings.weapon = nil
            settings.supported = false
            settings.targetId = 0
            settings.range = 0
            settings.targetDistance = 0
        end
        -- 0.01 resumes on the next engine scheduler frame in Hades.
        wait(0.01)
    end
end

local function restartRagebot()
    local settings = ragebotSettings()
    settings.generation = settings.generation + 1
    if ragebotEnabled(settings) then
        thread(ragebotLoop, settings.generation)
    else
        settings.targetId = 0
        settings.range = 0
        settings.targetDistance = 0
        clearRagebotTargeting()
    end
end

local function stopRagebot()
    local settings = ragebotSettings()
    settings.autoAim = false
    settings.autoFire = false
    settings.silentShot = false
    settings.generation = settings.generation + 1
    settings.targetId = 0
    settings.range = 0
    settings.targetDistance = 0
    clearRagebotTargeting()
end

local function ragebotState()
    local settings = ragebotSettings()
    local weapon,family = ragebotWeapon()
    return {weapon=weapon or "",supported=family ~= nil,autoAim=settings.autoAim,
        autoFire=settings.autoFire,silentShot=settings.silentShot,targetId=settings.targetId,
        range=settings.range or 0,targetDistance=settings.targetDistance or 0,
        targetPriority=settings.targetPriority,lockHold=settings.lockHold,fastSwitch=true,
        syncWeapons=settings.syncWeapons,perfectBow=settings.perfectBow,spreadMode=settings.spreadMode}
end

function HADES_TOOLS.Snapshot()
    local h = hero()
    maintainInfiniteCast(h)
    return {hero={objectId=h.ObjectId,health=h.Health,maxHealth=h.MaxHealth,traits=traits(h),superMeter=h.SuperMeter,
        dashCount=h.DashCount,weaponState=weaponState(h),
        speed=GetUnitDataValue({Id=h.ObjectId,Property="Speed"}),
        damageMultiplier=GetUnitDataValue({Id=h.ObjectId,Property="DamageOutputMultiplier"}),
        critAddition=GetUnitDataValue({Id=h.ObjectId,Property="CritAddition"}),
        god=h.InvulnerableFlags and h.InvulnerableFlags.HADES_TOOLS == true,
        infiniteCast=session.infiniteCast == true},
        ragebot=ragebotState(),
        run={room=CurrentRun.CurrentRoom.Name,money=CurrentRun.Money or 0,rerolls=CurrentRun.NumRerolls or 0},
        resources=ShallowCopyTable(GameState.Resources),version=HADES_TOOLS.Version}
end

function HADES_TOOLS.Catalog()
    local output = {}
    local sources={resources=ResourceData,consumables=ConsumableData,traits=TraitData,loot=LootData,weapons=WeaponData}
    for category,data in pairs(sources) do
        local rows = {}
        for key,item in pairs(data) do
            if type(key)=="string" and type(item)=="table" then
                local row={key=key,name=item.Name,icon=item.Icon,slot=item.Slot,hidden=item.Hidden == true,
                    heal=item.HealAmount,maxHealth=item.AddMaxHealth,
                    description=item.Description,displayName=item.DisplayName,rarities={},
                    heroWeapon=category=="weapons" and Contains(WeaponSets.HeroPhysicalWeapons,key)}
                for rarity in pairs(item.RarityLevels or {}) do table.insert(row.rarities,rarity) end
                table.sort(row.rarities)
                table.insert(rows,row)
            end
        end
        table.sort(rows,function(a,b)return a.key<b.key end)
        output[category]=rows
    end
    return output
end

function HADES_TOOLS.Diagnose()
    return {currentRun=CurrentRun~=nil,hero=CurrentRun and CurrentRun.Hero~=nil,
        dead=CurrentRun and CurrentRun.Hero and CurrentRun.Hero.IsDead,
        room=CurrentRun and CurrentRun.CurrentRoom and CurrentRun.CurrentRoom.Name,
        gameState=GameState~=nil,resourceData=ResourceData~=nil,
        requireFocusToUpdate=GetConfigOptionValue({Name="RequireFocusToUpdate"}),
        sessionActive=session.originalRequireFocus~=nil}
end

function HADES_TOOLS.Command(c)
    local result
    if c.action=="session_start" then
        if session.originalRequireFocus == nil then
            session.originalRequireFocus = GetConfigOptionValue({Name="RequireFocusToUpdate"})
        end
        SetConfigOption({Name="RequireFocusToUpdate",Value=false})
        return HADES_TOOLS.Diagnose()
    elseif c.action=="session_end" then
        stopRagebot()
        if session.infiniteCast and CurrentRun and CurrentRun.Hero then
            setInfiniteCast(CurrentRun.Hero, false)
        end
        if session.originalRequireFocus ~= nil then
            SetConfigOption({Name="RequireFocusToUpdate",Value=session.originalRequireFocus})
            session.originalRequireFocus = nil
        end
        return {done=true,requireFocusToUpdate=GetConfigOptionValue({Name="RequireFocusToUpdate"})}
    elseif c.action=="diagnose" then
        return HADES_TOOLS.Diagnose()
    elseif c.action=="snapshot" then
        return HADES_TOOLS.Snapshot()
    elseif c.action=="catalog" then
        return HADES_TOOLS.Catalog()
    end
    local h = hero()
    if c.action=="health" then
        local amount=number(c.value,1,h.MaxHealth)
        h.Health=amount
        UpdateHealthUI()
        result={value=h.Health}
    elseif c.action=="max_health" then
        h.MaxHealth=number(c.value,1,1000000)
        h.Health=math.min(h.Health,h.MaxHealth)
        UpdateHealthUI()
        result={value=h.MaxHealth}
    elseif c.action=="heal" then
        Heal(h,{HealAmount=h.MaxHealth,Silent=true})
        UpdateHealthUI()
        result={value=h.Health}
    elseif c.action=="god" then
        assert(type(c.value)=="boolean","God mode requires a boolean")
        if c.value then SetUnitInvulnerable(h,"HADES_TOOLS") else SetUnitVulnerable(h,"HADES_TOOLS") end
        result={value=c.value}
    elseif c.action=="infinite_cast" then
        assert(type(c.value)=="boolean","Infinite cast requires a boolean")
        setInfiniteCast(h,c.value)
        result={value=c.value}
    elseif c.action=="ragebot_option" then
        local options={autoAim=true,autoFire=true,silentShot=true,lockHold=true,syncWeapons=true,perfectBow=true}
        assert(options[c.option],"Unknown ragebot option")
        assert(type(c.value)=="boolean","Ragebot option requires a boolean")
        local settings=ragebotSettings()
        settings[c.option]=c.value
        restartRagebot()
        result={option=c.option,value=c.value}
    elseif c.action=="ragebot_mode" then
        assert(c.option=="targetPriority" or c.option=="spreadMode","Unknown ragebot mode")
        assert(type(c.value)=="string","Ragebot mode requires a string")
        if c.option=="targetPriority" then assert(RAGEBOT_TARGET_PRIORITIES[c.value],"Unknown target priority") end
        if c.option=="spreadMode" then assert(RAGEBOT_SPREAD_MODES[c.value],"Unknown spread mode") end
        local settings=ragebotSettings()
        settings[c.option]=c.value
        restartRagebot()
        result={option=c.option,value=c.value}
    elseif c.action=="attribute" then
        local allowed={Speed=true,DamageOutputMultiplier=true,CritAddition=true}
        assert(allowed[c.name],"Unknown editable unit property")
        local value=number(c.value,0,100000)
        SetUnitProperty({DestinationId=h.ObjectId,Property=c.name,Value=value})
        result={property=c.name,value=GetUnitDataValue({Id=h.ObjectId,Property=c.name})}
    elseif c.action=="resource" then
        assert(ResourceData[c.name]~=nil,"Unknown resource key")
        local value=number(c.value,0,1000000000)
        local before=GameState.Resources[c.name] or 0
        AddResource(c.name,value-before,"HADES_TOOLS",{NoLifetimeEffect=true,Silent=true,SkipOverheadText=true})
        result={name=c.name,before=before,after=GameState.Resources[c.name]}
    elseif c.action=="money" then
        CurrentRun.Money=number(c.value,0,1000000000)
        UpdateMoneyUI(CurrentRun.Money)
        result={value=CurrentRun.Money}
    elseif c.action=="rerolls" then
        CurrentRun.NumRerolls=number(c.value,0,10000)
        UpdateRerollUI(CurrentRun.NumRerolls)
        result={value=CurrentRun.NumRerolls}
    elseif c.action=="dash_count" then
        assert(type(h.DashCount)=="number","Hero.DashCount is unavailable in this game state")
        h.DashCount=number(c.value,1,100)
        result={value=h.DashCount}
    elseif c.action=="super_meter" then
        h.SuperMeter=number(c.value,0,100)
        result={value=h.SuperMeter}
    elseif c.action=="spawn_consumable" then
        local data=ConsumableData[c.name]
        assert(data and data.Name,"Unknown consumable key")
        local id=SpawnObstacle({Name=data.Name,DestinationId=h.ObjectId,Group="Standing",OffsetX=120})
        assert(id and id>0,"SpawnObstacle returned no object")
        local item=CreateConsumableItem(id,c.name,0)
        assert(item,"CreateConsumableItem returned no item")
        result={objectId=id,name=item.Name}
    elseif c.action=="spawn_loot" then
        local data=LootData[c.name]
        assert(data and data.Name,"Unknown loot key")
        local item=CreateLoot({Name=c.name,SpawnPoint=h.ObjectId,OffsetX=180,DoesNotBlockExit=true,SuppressSpawnSounds=true})
        result={objectId=item.ObjectId,name=item.Name}
    elseif c.action=="destroy_object" then
        local id=number(c.objectId,1,2147483647)
        Destroy({Id=id})
        result={objectId=id,destroyed=true,alive=IsAlive({Id=id})}
    elseif c.action=="add_trait" then
        assert(TraitData[c.name],"Unknown trait key")
        local rarity=c.rarity or "Common"
        local raritySet={Common=true,Rare=true,Epic=true,Heroic=true,Legendary=true}
        assert(raritySet[rarity],"Unknown rarity")
        AddTraitToHero({TraitName=c.name,Rarity=rarity})
        result={name=c.name,present=HeroHasTrait(c.name)}
    elseif c.action=="remove_trait" then
        assert(TraitData[c.name],"Unknown trait key")
        RemoveTrait(h,c.name)
        result={name=c.name,present=HeroHasTrait(c.name)}
    elseif c.action=="trait_property" then
        local trait=findTrait(h,c.name)
        assert(trait,"Trait is not active on the hero")
        assert(c.property=="StackNum","Unknown editable trait property")
        local target=math.floor(number(c.value,1,100))
        local current=GetTraitCount(h,trait)
        while current < target do
            AddTraitToHero({TraitName=c.name,Rarity=trait.Rarity,SkipNewTraitHighlight=true})
            current=GetTraitCount(h,trait)
        end
        while current > target do
            RemoveTrait(h,c.name)
            current=GetTraitNameCount(h,c.name)
        end
        result={name=c.name,property=c.property,value=current}
    elseif c.action=="trait_rarity" then
        local trait=findTrait(h,c.name)
        assert(trait,"Trait is not active on the hero")
        local raritySet={Common=true,Rare=true,Epic=true,Heroic=true,Legendary=true}
        assert(raritySet[c.rarity],"Unknown rarity")
        trait.Rarity=c.rarity
        result={name=c.name,property="Rarity",value=trait.Rarity}
    elseif c.action=="weapon_property" then
        assert(type(h.Weapons)=="table","Hero.Weapons table is unavailable")
        local weapon=h.Weapons[c.name]
        assert(type(weapon)=="table","Weapon is not active on the hero")
        local allowed={UpgradeLevel=true,AspectLevel=true,Level=true,Rank=true,DamageMultiplier=true}
        assert(allowed[c.property],"Unknown editable weapon property")
        assert(type(weapon[c.property])=="number","Weapon property is unavailable")
        weapon[c.property]=number(c.value,0,100000)
        result={name=c.name,property=c.property,value=weapon[c.property]}
    elseif c.action=="weapon" then
        assert(Contains(WeaponSets.HeroPhysicalWeapons,c.name),"Select one of the six hero weapons")
        EquipPlayerWeapon(WeaponData[c.name],{PreLoadBinks=true,LoadPackages=true})
        result={name=c.name}
    elseif c.action=="cleanup" then
        stopRagebot()
        if session.infiniteCast then setInfiniteCast(h,false) end
        SetUnitVulnerable(h,"HADES_TOOLS")
        result={done=true}
    else
        error("Unknown GM command: "..tostring(c.action))
    end
    local state=HADES_TOOLS.Snapshot()
    state.command=result
    return state
end
