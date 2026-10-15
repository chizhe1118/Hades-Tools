import QtQuick
import QtQuick.Layouts
import md3.Core

Flickable {
    id: page
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: content.implicitHeight + 48

    readonly property bool chinese: AppController.language === "zh"
    readonly property var hero: AppController.hero || ({})
    readonly property var run: AppController.run || ({})
    readonly property var traits: hero.traits || []
    readonly property var weaponState: hero.weaponState || ({available: false, entries: []})
    readonly property var weaponEntries: weaponState.entries || []
    readonly property var rarityValues: ["Common", "Rare", "Epic", "Heroic", "Legendary"]

    function t(zh, en) { return chinese ? zh : en }
    function rarityName(value) {
        const names = {Common: "普通", Rare: "稀有", Epic: "史诗", Heroic: "英雄", Legendary: "传奇"}
        return chinese && names[value] ? names[value] : (value || t("未标注", "Unspecified"))
    }
    function displayName(key) {
        return key ? AppController.traitsCatalog.displayName(key, AppController.language) : "—"
    }
    function editableWeaponFields(entry) {
        const fields = entry.fields || {}
        const names = ["UpgradeLevel", "AspectLevel", "Level", "Rank", "DamageMultiplier"]
        const result = []
        for (let i = 0; i < names.length; ++i) {
            const name = names[i]
            if (typeof fields[name] === "number") result.push({name: name, value: fields[name], weaponKey: entry.key})
        }
        return result
    }

    onChineseChanged: contentY = 0
    onVisibleChanged: if (visible) contentY = 0

    ColumnLayout {
        id: content
        width: Math.min(page.width - 48, 1120)
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                AppText {
                    text: page.t("自身状态", "Player State")
                    font.pixelSize: Theme.typography.headlineSmall.size
                    color: Theme.color.onSurfaceColor
                }
                AppText {
                    text: page.t("集中查看并编辑人物生命、战斗、本局数据、祝福与武器属性。",
                                 "Inspect and edit health, combat, run, boon and weapon attributes in one place.")
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: Theme.color.onSurfaceVariantColor
                }
            }
            AppText {
                text: AppController.connected ? page.t("实时状态", "Live state") : page.t("未连接", "Disconnected")
                color: AppController.connected ? Theme.color.primary : Theme.color.error
                font.pixelSize: Theme.typography.labelLarge.size
            }
        }

        SectionCard {
            Layout.fillWidth: true
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                AppText { text: "person"; font.family: Theme.iconFont.name; font.pixelSize: 25; color: Theme.color.primary }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    AppText { text: page.t("人物状态", "Hero State"); font.pixelSize: Theme.typography.titleLarge.size; color: Theme.color.onSurfaceColor }
                    AppText {
                        text: page.t("对象 ID：", "Object ID: ") + (hero.objectId === undefined ? "—" : hero.objectId)
                        color: Theme.color.onSurfaceVariantColor
                    }
                }
                Button { text: page.t("刷新", "Refresh"); icon: "refresh"; type: "outlined"; enabled: AppController.connected && !AppController.busy; onClicked: AppController.refresh() }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: page.width >= 900 ? 3 : (page.width >= 650 ? 2 : 1)
                columnSpacing: 20
                rowSpacing: 12
                AttributeEditor { label: page.t("当前生命", "Current Health"); icon: "favorite"; liveValue: hero.health; onSubmitted: value => AppController.setNumber("health", value) }
                AttributeEditor { label: page.t("最大生命", "Max Health"); icon: "health_and_safety"; liveValue: hero.maxHealth; onSubmitted: value => AppController.setNumber("max_health", value) }
                AttributeEditor { label: page.t("冲刺次数", "Dash Count"); icon: "directions_run"; liveValue: hero.dashCount; onSubmitted: value => AppController.setDashCount(value) }
                AttributeEditor { label: page.t("神力值", "Super Meter"); icon: "flash_on"; liveValue: hero.superMeter; onSubmitted: value => AppController.setNumber("super_meter", value) }
                AttributeEditor { label: page.t("移动速度", "Movement Speed"); icon: "speed"; liveValue: hero.speed; onSubmitted: value => AppController.setAttribute("Speed", value) }
                AttributeEditor { label: page.t("伤害倍率", "Damage Multiplier"); icon: "bolt"; liveValue: hero.damageMultiplier; onSubmitted: value => AppController.setAttribute("DamageOutputMultiplier", value) }
                AttributeEditor { label: page.t("暴击加成", "Critical Bonus"); icon: "gps_fixed"; liveValue: hero.critAddition; onSubmitted: value => AppController.setAttribute("CritAddition", value) }
                AttributeEditor { label: page.t("本局金币", "Run Money"); icon: "paid"; liveValue: page.run.money; onSubmitted: value => AppController.setNumber("money", value) }
                AttributeEditor { label: page.t("重掷次数", "Rerolls"); icon: "casino"; liveValue: page.run.rerolls; onSubmitted: value => AppController.setNumber("rerolls", value) }
            }
            AppText {
                visible: hero.dashCount === undefined
                text: page.t("当前游戏状态没有公开冲刺次数字段，连接后会按运行时数据展示。",
                             "The current game state does not expose a dash-count field; the runtime value will appear when available.")
                color: Theme.color.onSurfaceVariantColor
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        SectionCard {
            Layout.fillWidth: true
            AppText { text: page.t("当前祝福与强化", "Active Boons and Upgrades"); font.pixelSize: Theme.typography.titleLarge.size; color: Theme.color.onSurfaceColor }
            AppText {
                text: page.t("等级按游戏原生同名祝福实例数读取；修改后会重新读取人物状态。", "Levels use the game's native count of matching boon instances and are read back after changes.")
                color: Theme.color.onSurfaceVariantColor
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            AppText {
                visible: page.traits.length === 0
                text: AppController.connected ? page.t("当前没有可编辑的祝福", "No editable boons are active") : page.t("连接游戏后读取祝福", "Connect to read active boons")
                color: Theme.color.onSurfaceVariantColor
            }
            Repeater {
                model: page.traits
                delegate: SectionCard {
                    required property var modelData
                    Layout.fillWidth: true
                    padding: 14
                    spacing: 10
                    type: "filled"
                    RowLayout {
                        Layout.fillWidth: true
                        AppText { text: "auto_awesome"; font.family: Theme.iconFont.name; font.pixelSize: 22; color: Theme.color.primary }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            AppText { text: page.displayName(modelData.name); color: Theme.color.onSurfaceColor; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
                            AppText {
                                text: (modelData.slot || page.t("未分类", "Unclassified")) + "  ·  " + page.rarityName(modelData.rarity)
                                font.pixelSize: 12
                                color: Theme.color.onSurfaceVariantColor
                                Layout.fillWidth: true
                            }
                        }
                    }
                    AppText {
                        visible: modelData.description !== undefined && modelData.description !== ""
                        text: modelData.description || ""
                        color: Theme.color.onSurfaceVariantColor
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        AttributeEditor {
                            label: page.t("等级", "Level")
                            icon: "stacked_bar_chart"
                            liveValue: modelData.level
                            onSubmitted: value => AppController.setTraitLevel(modelData.name, value)
                        }
                        ComboBox {
                            id: rarity
                            Layout.preferredWidth: 180
                            label: page.t("稀有度", "Rarity")
                            model: page.rarityValues.map(value => ({text: page.rarityName(value), value: value}))
                            currentIndex: Math.max(0, page.rarityValues.indexOf(modelData.rarity))
                            enabled: AppController.connected && !AppController.busy
                            onActivated: index => AppController.setTraitRarity(modelData.name, currentValue)
                        }
                    }
                }
            }
        }

        SectionCard {
            Layout.fillWidth: true
            AppText { text: page.t("当前武器强化", "Active Weapon Upgrades"); font.pixelSize: Theme.typography.titleLarge.size; color: Theme.color.onSurfaceColor }
            AppText {
                text: page.weaponState.available
                      ? page.t("可编辑字段来自当前人物的武器表。", "Editable fields are read from the active hero weapon table.")
                      : page.t("当前运行时没有公开武器属性表。", "The current runtime does not expose a weapon property table.")
                color: Theme.color.onSurfaceVariantColor
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Repeater {
                model: page.weaponEntries
                delegate: SectionCard {
                    required property var modelData
                    Layout.fillWidth: true
                    padding: 14
                    spacing: 10
                    type: "filled"
                    RowLayout {
                        Layout.fillWidth: true
                        AppText { text: "sports_martial_arts"; font.family: Theme.iconFont.name; font.pixelSize: 22; color: Theme.color.primary }
                        AppText { text: modelData.key; color: Theme.color.onSurfaceColor; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 12
                        Repeater {
                            model: page.editableWeaponFields(modelData)
                            delegate: AttributeEditor {
                                required property var modelData
                                width: Math.max(220, (page.width - 110) / 3)
                                label: modelData.name
                                icon: "tune"
                                liveValue: modelData.value
                                onSubmitted: value => AppController.setWeaponProperty(modelData.weaponKey, modelData.name, value)
                            }
                        }
                    }
                }
            }
            AppText {
                visible: page.weaponEntries.length === 0
                text: page.t("连接后读取当前武器及其强化字段", "Connect to read the active weapon and its upgrade fields")
                color: Theme.color.onSurfaceVariantColor
            }
        }
    }

    ScrollBar {
        parent: page
        target: page
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }
}
