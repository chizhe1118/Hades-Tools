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
    readonly property var hero: AppController.hero
    readonly property var run: AppController.run
    readonly property var traits: hero.traits || []
    readonly property real healthRatio: hero.maxHealth > 0 && hero.health !== undefined
                                             ? Math.max(0, Math.min(1, hero.health / hero.maxHealth)) : 0
    onChineseChanged: contentY = 0
    onVisibleChanged: if (visible) contentY = 0

    function t(zh, en) { return chinese ? zh : en }
    function value(number) { return number === undefined || number === null ? "—" : String(number) }
    function rarityName(rarity) {
        const names = {Common: "普通", Rare: "稀有", Epic: "史诗", Heroic: "英雄", Legendary: "传奇"}
        return rarity ? (chinese && names[rarity] ? names[rarity] : rarity) : t("未标注稀有度", "No rarity")
    }
    function slotName(slot) {
        const names = {Melee: "攻击", Secondary: "特殊", Ranged: "投弹", Rush: "冲刺", Shout: "祈援", Keepsake: "信物", Assist: "伙伴"}
        return slot ? (chinese && names[slot] ? names[slot] : slot) : t("未标注类别", "Unspecified slot")
    }

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
                spacing: 6
                AppText {
                    text: page.t("人物概览", "Character Overview")
                    font.pixelSize: Theme.typography.headlineSmall.size
                    color: Theme.color.onSurfaceColor
                }
                AppText {
                    text: page.t("当前人物、本局状态与已有效果", "Current hero, run state and active effects")
                    color: Theme.color.onSurfaceVariantColor
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
            AppText {
                text: AppController.hasError ? page.t("状态异常", "State error")
                      : (AppController.connected && AppController.lastUpdated ? page.t("每秒刷新", "Updates every second") : page.t("等待读取", "Waiting for state"))
                color: Theme.color.primary
                font.pixelSize: 12
            }
        }

        SectionCard {
            Layout.fillWidth: true
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 16
                    color: Theme.color.primaryContainer
                    AppText {
                        anchors.centerIn: parent
                        text: "person"
                        font.family: Theme.iconFont.name
                        font.weight: Font.Normal
                        font.pixelSize: 28
                        color: Theme.color.onPrimaryContainerColor
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    AppText {
                        text: page.t("当前人物", "Current Hero")
                        font.pixelSize: Theme.typography.titleLarge.size
                        color: Theme.color.onSurfaceColor
                    }
                    AppText {
                        text: page.t("房间：", "Room: ") + (page.run.room || "—")
                              + "   ·   " + page.t("人物 ID：", "Hero ID: ") + page.value(page.hero.objectId)
                        color: Theme.color.onSurfaceVariantColor
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                AppText { text: "favorite"; font.family: Theme.iconFont.name; font.weight: Font.Normal; font.pixelSize: 22; color: Theme.color.primary }
                AppText { text: page.t("生命", "Health"); color: Theme.color.onSurfaceVariantColor }
                AppText {
                    text: page.value(page.hero.health) + " / " + page.value(page.hero.maxHealth)
                    font.pixelSize: 28
                    color: Theme.color.onSurfaceColor
                    Layout.fillWidth: true
                }
                AppText {
                    text: page.hero.maxHealth > 0 ? Math.round(page.healthRatio * 100) + "%" : "—"
                    color: Theme.color.primary
                }
            }
            LinearProgress { Layout.fillWidth: true; value: page.healthRatio }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: page.width >= 880 ? 4 : 2
            columnSpacing: 12
            rowSpacing: 12
            MetricCard { label: page.t("移动速度", "Movement Speed"); value: page.value(page.hero.speed); icon: "speed"; detail: page.t("当前移动属性", "Current movement stat") }
            MetricCard { label: page.t("伤害倍率", "Damage Multiplier"); value: page.value(page.hero.damageMultiplier); icon: "bolt"; detail: page.t("伤害输出乘数", "Damage output multiplier") }
            MetricCard { label: page.t("暴击加成", "Critical Bonus"); value: page.value(page.hero.critAddition); icon: "gps_fixed"; detail: page.t("当前暴击属性", "Current critical stat") }
            MetricCard { label: page.t("神力值", "God Gauge"); value: page.value(page.hero.superMeter); icon: "flash_on"; detail: page.t("当前神力读数", "Current meter value") }
            MetricCard { label: page.t("本局金币", "Run Money"); value: page.value(page.run.money); icon: "paid"; detail: page.t("当前逃脱持有", "Available in this run") }
            MetricCard { label: page.t("重掷次数", "Rerolls"); value: page.value(page.run.rerolls); icon: "casino"; detail: page.t("当前剩余次数", "Remaining in this run") }
            MetricCard { label: page.t("已有效果", "Active Effects"); value: page.hero.traits ? String(page.traits.length) : "—"; icon: "auto_awesome"; detail: page.t("祝福、信物及其他特性", "Boons, keepsakes and traits") }
            MetricCard { label: page.t("工具无敌", "GM Invulnerability"); value: page.hero.god === undefined ? "—" : (page.hero.god ? page.t("已开启", "On") : page.t("已关闭", "Off")); icon: "shield"; detail: page.t("本工具设置的无敌状态", "State set by this tool") }
        }

        SectionCard {
            Layout.fillWidth: true
            RowLayout {
                Layout.fillWidth: true
                AppText { text: "auto_awesome"; font.family: Theme.iconFont.name; font.weight: Font.Normal; font.pixelSize: 24; color: Theme.color.primary }
                AppText {
                    text: page.t("祝福与人物效果", "Boons and Hero Effects")
                    font.pixelSize: Theme.typography.titleLarge.size
                    color: Theme.color.onSurfaceColor
                    Layout.fillWidth: true
                }
                AppText { text: String(page.traits.length); color: Theme.color.primary }
            }
            AppText {
                visible: page.traits.length === 0
                text: page.hero.traits ? page.t("当前人物没有已记录的效果", "No active effects recorded for this hero") : page.t("连接游戏后显示人物效果", "Connect to view hero effects")
                color: Theme.color.onSurfaceVariantColor
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Repeater {
                model: page.traits
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.color.outlineVariant }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        AppText {
                            text: modelData.slot === "Keepsake" ? "diamond" : "auto_awesome"
                            font.family: Theme.iconFont.name
                            font.weight: Font.Normal
                            font.pixelSize: 22
                            color: Theme.color.primary
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            AppText { text: modelData.name ? AppController.traitsCatalog.displayName(modelData.name, AppController.language) : "—"; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; color: Theme.color.onSurfaceColor }
                            AppText {
                                text: page.slotName(modelData.slot) + "  ·  " + page.rarityName(modelData.rarity)
                                      + (modelData.level !== undefined ? "  ·  " + page.t("等级 ", "Level ") + modelData.level : "")
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                font.pixelSize: 12
                                color: Theme.color.onSurfaceVariantColor
                            }
                        }
                    }
                }
            }
        }
        AppText {
            text: AppController.lastUpdated ? page.t("最近读取：", "Last read: ") + AppController.lastUpdated : page.t("连接游戏后自动刷新人物数据", "Connect to automatically refresh hero data")
            color: Theme.color.onSurfaceVariantColor
            font.pixelSize: 12
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
