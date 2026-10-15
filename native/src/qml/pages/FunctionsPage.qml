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
    readonly property var ragebot: AppController.ragebot || ({})

    function ragebotWeaponName(name) {
        if (name === "GunWeapon") return t("狮鹫坚炮", "Adamant Rail")
        if (name === "BowWeapon") return t("索心弓", "Heart-Seeking Bow")
        return name ? name : t("未装备武器", "No weapon equipped")
    }

    function t(zh, en) { return chinese ? zh : en }
    function priorityLabel(value) {
        if (value === "lowest_health") return t("最低生命值", "Lowest health")
        if (value === "elite") return t("精英优先", "Elite first")
        if (value === "boss") return t("Boss 优先", "Boss first")
        return t("最近目标", "Nearest")
    }
    function spreadLabel(value) {
        if (value === "seed_check") return t("Seed Check / 扩散预测", "Seed Check")
        if (value === "remove_spread") return t("Remove Spread / 移除扩散", "Remove Spread")
        return t("Off / 关闭", "Off")
    }

    onChineseChanged: contentY = 0
    onVisibleChanged: if (visible) contentY = 0

    ColumnLayout {
        id: content
        width: Math.min(page.width - 48, 1120)
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        spacing: 18

        AppText {
            text: page.t("功能", "Functions")
            font.pixelSize: Theme.typography.headlineSmall.size
            color: Theme.color.onSurfaceColor
        }
        AppText {
            text: page.t("集中管理持续生效的战斗功能和高频快捷操作。", "Manage persistent combat features and frequent actions.")
            color: Theme.color.onSurfaceVariantColor
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        SectionCard {
            Layout.fillWidth: true
            AppText {
                text: page.t("核心功能", "Core Features")
                font.pixelSize: Theme.typography.titleLarge.size
                color: Theme.color.onSurfaceColor
            }
            GridLayout {
                Layout.fillWidth: true
                columns: page.width >= 780 ? 2 : 1
                columnSpacing: 18
                rowSpacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    AppText { text: "shield"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        AppText { text: page.t("无敌", "God Mode"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { text: page.t("阻止玩家受到伤害", "Prevent damage to the player"); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12 }
                    }
                    Switch {
                        checked: Boolean(page.hero.god)
                        enabled: AppController.connected && !AppController.busy
                        onClicked: AppController.setGod(checked)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    AppText { text: "all_inclusive"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        AppText { text: page.t("无限投弹", "Infinite Cast"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { text: page.t("持续补充投弹弹药", "Continuously replenish cast ammo"); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12 }
                    }
                    Switch {
                        checked: Boolean(page.hero.infiniteCast)
                        enabled: AppController.connected && !AppController.busy
                        onClicked: AppController.setInfiniteCast(checked)
                    }
                }
            }
        }

        SectionCard {
            Layout.fillWidth: true
            AppText {
                text: "Ragebot"
                font.pixelSize: Theme.typography.titleLarge.size
                color: Theme.color.onSurfaceColor
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                AppText {
                    text: page.ragebot.supported ? "check_circle" : "do_not_disturb_on"
                    font.family: Theme.iconFont.name
                    font.pixelSize: 20
                    color: page.ragebot.supported ? Theme.color.primary : Theme.color.onSurfaceVariantColor
                }
                AppText {
                    Layout.fillWidth: true
                    text: page.ragebot.supported
                          ? page.t("当前武器：", "Current weapon: ") + page.ragebotWeaponName(page.ragebot.weapon)
                          : page.t("仅在装备狮鹫坚炮或索心弓时生效", "Active only with the Adamant Rail or Heart-Seeking Bow")
                    color: Theme.color.onSurfaceVariantColor
                    wrapMode: Text.WordWrap
                }
                AppText {
                    visible: Number(page.ragebot.targetId) > 0
                    text: page.t("目标 #", "Target #") + Number(page.ragebot.targetId)
                          + "  " + Math.round(Number(page.ragebot.targetDistance))
                          + " / " + Math.round(Number(page.ragebot.range))
                    color: Theme.color.primary
                    font.pixelSize: 12
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: page.width >= 780 ? 2 : 1
                columnSpacing: 18
                rowSpacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    AppText { text: "my_location"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        AppText { text: page.t("自动瞄准", "Auto Aim"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { Layout.fillWidth: true; text: page.t("持续锁定视线内最近的有效敌人", "Track the nearest valid enemy with line of sight"); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    }
                    Switch {
                        checked: Boolean(page.ragebot.autoAim)
                        enabled: AppController.connected && !AppController.busy
                        onClicked: AppController.setRagebotOption("autoAim", checked)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    AppText { text: "flash_on"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        AppText { text: page.t("自动开火", "Auto Fire"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { Layout.fillWidth: true; text: page.t("按当前武器射速向锁定目标开火", "Fire at the locked target using the current weapon cadence"); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    }
                    Switch {
                        checked: Boolean(page.ragebot.autoFire)
                        enabled: AppController.connected && !AppController.busy
                        onClicked: AppController.setRagebotOption("autoFire", checked)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    AppText { text: "visibility_off"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        AppText { text: page.t("静默射击", "Silent Shot"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                         AppText { Layout.fillWidth: true; text: page.t("子弹按锁定目标方向飞行，同时保持角色与准星朝向", "Send projectiles toward the locked target while preserving character and reticle direction"); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    }
                    Switch {
                        checked: Boolean(page.ragebot.silentShot)
                        enabled: AppController.connected && !AppController.busy
                        onClicked: AppController.setRagebotOption("silentShot", checked)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    AppText { text: "track_changes"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        AppText { text: page.t("目标优先级", "Target Priority"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { text: page.priorityLabel(page.ragebot.targetPriority); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12 }
                    }
                    ComboBox {
                        Layout.preferredWidth: 180
                        model: [
                            {text: page.t("最近目标", "Nearest"), value: "nearest"},
                            {text: page.t("最低生命值", "Lowest health"), value: "lowest_health"},
                            {text: page.t("精英优先", "Elite first"), value: "elite"},
                            {text: page.t("Boss 优先", "Boss first"), value: "boss"}
                        ]
                        currentIndex: Math.max(0, ["nearest", "lowest_health", "elite", "boss"].indexOf(page.ragebot.targetPriority || "nearest"))
                        enabled: AppController.connected && !AppController.busy
                        onActivated: index => AppController.setRagebotMode("targetPriority", currentValue)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    AppText { text: "lock"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        AppText { text: page.t("锁定保持", "Lock Hold"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { text: page.t("目标失效前保持锁定，失效时立即快速换锁", "Keep the target until invalid, then switch immediately"); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    }
                    Switch { checked: page.ragebot.lockHold !== false; enabled: AppController.connected && !AppController.busy; onClicked: AppController.setRagebotOption("lockHold", checked) }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    AppText { text: "sync"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        AppText { text: page.t("武器同步", "Weapon Sync"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { text: page.t("同步坚炮与弓的锁定、静默和开火状态", "Synchronize lock, silent shot, and fire state for rail and bow"); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    }
                    Switch { checked: page.ragebot.syncWeapons !== false; enabled: AppController.connected && !AppController.busy; onClicked: AppController.setRagebotOption("syncWeapons", checked) }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    AppText { text: "center_focus_strong"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        AppText { text: page.t("弓箭完美闪光", "Perfect Bow Window"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { text: page.t("同步原生闪光窗口出箭，确保每次都是完美箭", "Release inside the native flash window for perfect arrows"); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    }
                    Switch { checked: page.ragebot.perfectBow !== false; enabled: AppController.connected && !AppController.busy; onClicked: AppController.setRagebotOption("perfectBow", checked) }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    AppText { text: "blur_on"; font.family: Theme.iconFont.name; font.pixelSize: 24; color: Theme.color.primary }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        AppText { text: page.t("散射模式", "Spread Mode"); color: Theme.color.onSurfaceColor; font.pixelSize: Theme.typography.titleMedium.size }
                        AppText { text: page.spreadLabel(page.ragebot.spreadMode); color: Theme.color.onSurfaceVariantColor; font.pixelSize: 12 }
                    }
                    ComboBox {
                        Layout.preferredWidth: 220
                        model: [
                            {text: page.t("Off / 关闭", "Off"), value: "off"},
                            {text: page.t("Seed Check / 扩散预测", "Seed Check"), value: "seed_check"},
                            {text: page.t("Remove Spread / 移除扩散", "Remove Spread"), value: "remove_spread"}
                        ]
                        currentIndex: Math.max(0, ["off", "seed_check", "remove_spread"].indexOf(page.ragebot.spreadMode || "remove_spread"))
                        enabled: AppController.connected && !AppController.busy
                        onActivated: index => AppController.setRagebotMode("spreadMode", currentValue)
                    }
                }
                AppText {
                    Layout.fillWidth: true
                    Layout.columnSpan: page.width >= 780 ? 2 : 1
                    text: page.t("快速换锁：已启用。当前目标死亡、无敌、遮挡或超出攻击距离时，下一帧立即按优先级选择新目标。",
                                 "Fast switch: enabled. When the target dies, becomes invulnerable, obscured, or leaves range, the next frame selects a new target by priority.")
                    color: Theme.color.primary; font.pixelSize: 12; wrapMode: Text.WordWrap
                }

                AppText {
                    Layout.fillWidth: true
                    Layout.columnSpan: page.width >= 780 ? 2 : 1
                     text: page.t("静默射击启用时子弹使用锁定目标方向；角色与准星保持当前朝向，切换武器或关闭功能后会恢复原始瞄准属性。",
                                  "Silent Shot uses the locked target direction for projectiles while the character and reticle keep their current direction; original targeting properties are restored when switching weapons or disabling the feature.")
                    color: Theme.color.onSurfaceVariantColor
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }

        SectionCard {
            Layout.fillWidth: true
            AppText {
                text: page.t("快捷操作", "Quick Actions")
                font.pixelSize: Theme.typography.titleLarge.size
                color: Theme.color.onSurfaceColor
            }
            RowLayout {
                Layout.fillWidth: true
                enabled: AppController.connected && !AppController.busy
                spacing: 12
                Button { text: page.t("完全治疗", "Full Heal"); icon: "favorite"; type: "filled"; onClicked: AppController.setNumber("heal", 0) }
                Button { text: page.t("刷新状态", "Refresh State"); icon: "refresh"; type: "outlined"; onClicked: AppController.refresh() }
                Item { Layout.fillWidth: true }
            }
        }

        AppText {
            text: AppController.lastUpdated
                  ? page.t("状态时间：", "State time: ") + AppController.lastUpdated
                  : page.t("连接游戏后启用功能", "Connect to enable features")
            color: Theme.color.onSurfaceVariantColor
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
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
