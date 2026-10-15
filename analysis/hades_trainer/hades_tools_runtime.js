const PROFILE = __PROFILE__;
const module = Process.getModuleByName(PROFILE.module);
for (const [name, spec] of Object.entries(PROFILE.api)) {
  if (!spec.expected_bytes) continue;
  const p = module.base.add(parseInt(spec.rva, 16));
  const actual = Array.from(new Uint8Array(p.readByteArray(16))).map(x=>x.toString(16).padStart(2,'0')).join(' ');
  if (actual !== spec.expected_bytes) throw new Error('Code bytes mismatch: '+name);
}
function api(name, result, args) { return new NativeFunction(module.base.add(parseInt(PROFILE.api[name].rva,16)),result,args); }
const load = api('luaL_loadbufferx','int',['pointer','pointer','uint64','pointer','pointer']);
const pcall = api('lua_pcallk','int',['pointer','int','int','int','int','pointer']);
const gettop = api('lua_gettop','int',['pointer']);
const settop = api('lua_settop','void',['pointer','int']);
const tostring = api('lua_tolstring','pointer',['pointer','int','pointer']);
const chunkName = Memory.allocUtf8String('@HADES_TOOLS/GM.lua');
const luaSlot = module.base.add(parseInt(PROFILE.api.lua_state_slot.rva,16));
const pending = [];
let busy = false;
let player = ptr(0);
let lastError = null;

function execute(source) {
  const L = luaSlot.readPointer();
  if (L.isNull()) throw new Error('Game Lua state is not initialized');
  const top = gettop(L);
  const buffer = Memory.allocUtf8String(source);
  try {
    let status = load(L,buffer,unescape(encodeURIComponent(source)).length,chunkName,ptr(0));
    if (status === 0) status = pcall(L,0,1,0,0,ptr(0));
    if (status !== 0) {
      const err = tostring(L,-1,ptr(0));
      throw new Error(err.isNull() ? 'Lua status '+status : err.readUtf8String());
    }
    const value = tostring(L,-1,ptr(0));
    if (value.isNull()) throw new Error('Lua command returned no JSON');
    return {value:JSON.parse(value.readUtf8String()),thread:Process.getCurrentThreadId(),luaState:L.toString()};
  } finally {
    settop(L,top);
  }
}

function nativeSnapshot(expectedId) {
  if (player.isNull()) return {ready:false};
  const f=PROFILE.fields;
  try {
    const id=player.add(f.player_object_id).readU32();
    if (id!==expectedId) return {ready:false,reason:'Room/player changed'};
    const life=player.add(f.player_life).readPointer();
    const data=player.add(f.player_data).readPointer();
    if (life.isNull() || data.isNull() || life.add(f.life_player_controlled).readU8()!==1 || !life.add(f.life_owner).readPointer().equals(player)) throw new Error('Player identity validation failed');
    return {ready:true,player:player.toString(),life:life.toString(),data:data.toString(),objectId:id,x:player.add(f.player_x).readFloat(),y:player.add(f.player_y).readFloat(),speedModifier:player.add(f.player_speed_modifier).readFloat(),speedBase:data.add(f.data_speed).readFloat(),damageMultiplier:data.add(f.data_damage_multiplier).readFloat(),critAddition:data.add(f.data_crit_addition).readFloat(),invulnerable:life.add(f.life_invulnerable).readU8()};
  } catch(e) { throw new Error('Native snapshot failed: '+e); }
}

Interceptor.attach(module.base.add(parseInt(PROFILE.api.player_hook.rva,16)), {
  onEnter() {
    const p=this.context.rsi;
    const l=p.add(PROFILE.fields.player_life).readPointer();
    if (!l.isNull() && l.add(PROFILE.fields.life_player_controlled).readU8()===1) player=p;
  }
});
Interceptor.attach(module.base.add(parseInt(PROFILE.api.script_tick.rva,16)), {
  onEnter() {
    if (busy || pending.length===0) return;
    busy=true;
    const job=pending.shift();
    clearTimeout(job.timer);
    try {
      const result=execute(job.source);
      if (result.value.hero && result.value.hero.objectId) result.native=nativeSnapshot(result.value.hero.objectId);
      job.resolve(result);
    } catch(e) {
      lastError=String(e);job.reject(new Error(lastError));
    } finally { busy=false; }
  }
});
rpc.exports = {
  evaluate(source, timeout) {
    return new Promise((resolve,reject)=>{
      const job={source,resolve,reject,timer:null};
      job.timer=setTimeout(()=>{
        const i=pending.indexOf(job);if(i>=0)pending.splice(i,1);
        reject(new Error('Game-thread timeout; focus the game and close pause menus'));
      },timeout);
      pending.push(job);
    });
  },
  native(){
    if (player.isNull()) return {ready:false};
    return nativeSnapshot(player.add(PROFILE.fields.player_object_id).readU32());
  },
  info(){return {pid:Process.id,base:module.base.toString(),module:module.path,luaState:luaSlot.readPointer().toString(),lastError};}
};
