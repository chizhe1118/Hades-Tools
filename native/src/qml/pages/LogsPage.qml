import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: page
    readonly property bool chinese: AppController.language === "zh"

    function t(zh, en) { return chinese ? zh : en }
    function taskLabel(action) {
        const labels = {
            "connect": t("连接游戏", "Connect to Game"),
            "snapshot": t("手动刷新", "Manual Refresh"),
            "auto_refresh": t("自动刷新", "Automatic Refresh"),
            "catalog": t("读取目录", "Read Catalog"),
            "heal": t("治疗", "Heal"),
            "health": t("设置生命", "Set Health"),
            "max_health": t("设置生命上限", "Set Max Health"),
            "money": t("设置金币", "Set Money"),
            "rerolls": t("设置重掷", "Set Rerolls"),
            "dash_count": t("设置冲刺次数", "Set Dash Count"),
            "super_meter": t("设置神力值", "Set Super Meter"),
            "god": t("设置无敌", "Set God Mode"),
            "attribute": t("修改属性", "Set Attribute"),
            "resource": t("修改资源", "Set Resource"),
            "spawn_consumable": t("生成道具", "Spawn Item"),
            "spawn_loot": t("生成奖励", "Spawn Reward"),
            "destroy_object": t("清理对象", "Clean Up Object"),
            "add_trait": t("添加祝福", "Add Boon"),
            "remove_trait": t("移除祝福", "Remove Boon"),
            "trait_property": t("修改祝福等级", "Set Boon Level"),
            "trait_rarity": t("修改祝福稀有度", "Set Boon Rarity"),
            "weapon": t("装备武器", "Equip Weapon"),
            "weapon_property": t("修改武器强化", "Set Weapon Upgrade"),
            "bridge_exit": t("连接服务退出", "Bridge Exit")
        }
        return labels[action] || action
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            AppText {
                text: page.t("任务日志", "Task Logs")
                font.pixelSize: Theme.typography.headlineSmall.size
                color: Theme.color.onSurfaceColor
                Layout.fillWidth: true
            }
            AppText {
                text: page.t(AppController.logs.length + " 条记录", AppController.logs.length + " records")
                color: Theme.color.onSurfaceVariantColor
            }
            Button {
                text: page.t("清空", "Clear")
                icon: "delete_sweep"
                type: "outlined"
                enabled: AppController.logs.length > 0
                onClicked: AppController.clearLogs()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: Theme.shape.cornerSmall
            color: Theme.color.surfaceContainer
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 14
                AppText { text: page.t("时间", "Time"); color: Theme.color.onSurfaceVariantColor; font.bold: true; Layout.minimumWidth: 156; Layout.maximumWidth: 156 }
                AppText { text: page.t("任务", "Task"); color: Theme.color.onSurfaceVariantColor; font.bold: true; Layout.minimumWidth: 150; Layout.maximumWidth: 150 }
                AppText { text: page.t("参数 / 目标", "Parameters / Target"); color: Theme.color.onSurfaceVariantColor; font.bold: true; Layout.fillWidth: true; Layout.minimumWidth: 0; elide: Text.ElideRight }
                AppText { text: page.t("结果", "Result"); color: Theme.color.onSurfaceVariantColor; font.bold: true; Layout.minimumWidth: 240; Layout.maximumWidth: 240 }
            }
        }

        ListView {
            id: logList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: AppController.logs
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: logList.width
                height: Math.max(58, row.implicitHeight + 20)
                radius: Theme.shape.cornerExtraSmall
                color: index % 2 === 0 ? Theme.color.surfaceContainerLow : "transparent"
                RowLayout {
                    id: row
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 14
                    AppText { text: modelData.timestamp; color: Theme.color.onSurfaceVariantColor; font.family: "Consolas"; Layout.minimumWidth: 156; Layout.maximumWidth: 156 }
                    AppText { text: page.taskLabel(modelData.action); color: Theme.color.onSurfaceColor; font.weight: UiStyle.chinese ? Font.Bold : Font.Medium; wrapMode: Text.WordWrap; Layout.minimumWidth: 150; Layout.maximumWidth: 150 }
                    AppText { text: modelData.details || "—"; color: Theme.color.onSurfaceVariantColor; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true; Layout.minimumWidth: 0 }
                    ColumnLayout {
                        Layout.minimumWidth: 240
                        Layout.maximumWidth: 240
                        spacing: 4
                        RowLayout {
                            spacing: 8
                            AppText {
                                text: modelData.outcome === "success" ? "check_circle" : (modelData.outcome === "cancelled" ? "cancel" : "error")
                                font.family: Theme.iconFont.name
                                font.weight: Font.Normal
                                font.pixelSize: 18
                                color: modelData.outcome === "success" ? Theme.color.primary : Theme.color.error
                            }
                            AppText {
                                text: modelData.outcome === "success" ? page.t("成功", "Success") : (modelData.outcome === "cancelled" ? page.t("已取消", "Cancelled") : page.t("失败", "Failed"))
                                color: modelData.outcome === "success" ? Theme.color.primary : Theme.color.error
                            }
                        }
                        AppText {
                            visible: text.length > 0
                            text: modelData.message
                            color: modelData.outcome === "success" ? Theme.color.primary : Theme.color.error
                            wrapMode: Text.WrapAnywhere
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }
                    }
                }
            }

            AppText {
                anchors.centerIn: parent
                visible: logList.count === 0
                text: page.t("暂无任务记录", "No task records")
                color: Theme.color.onSurfaceVariantColor
                font.pixelSize: Theme.typography.titleMedium.size
            }
        }
    }
}
