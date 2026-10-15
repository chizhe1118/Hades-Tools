import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: page
    property string title
    property string subtitle
    property var catalog
    property string action
    property string actionText
    property string secondaryAction
    property string secondaryActionText
    property string selectedKey
    property string selectedEnglishName
    property string selectedChineseName
    readonly property bool chinese: AppController.language === "zh"

    function t(zh, en) { return chinese ? zh : en }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            AppText { text: page.title; font.pixelSize: Theme.typography.headlineSmall.size; color: Theme.color.onSurfaceColor; Layout.fillWidth: true }
            AppText { text: page.subtitle; color: Theme.color.onSurfaceVariantColor }
        }
        CatalogSearch { catalog: page.catalog }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16
            Card {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.fillHeight: true
                type: "outlined"
                padding: 16
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12
                    AppText {
                        text: page.catalog ? page.t(page.catalog.count + " 个条目", page.catalog.count + " entries") : page.t("等待连接", "Waiting for connection")
                        color: Theme.color.onSurfaceVariantColor
                    }
                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: page.catalog
                        delegate: Rectangle {
                            required property string key
                            required property string chineseName
                            required property string englishName
                            width: list.width
                            height: 62
                            radius: Theme.shape.cornerSmall
                            color: page.selectedKey === key ? Theme.color.secondaryContainer : (hover.containsMouse ? Theme.color.surfaceContainerHighest : "transparent")
                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 4
                                AppText {
                                    text: page.chinese ? chineseName : englishName
                                    color: page.selectedKey === key ? Theme.color.onSecondaryContainerColor : Theme.color.onSurfaceColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                AppText { text: key; font.pixelSize: 11; color: Theme.color.onSurfaceVariantColor; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: { page.selectedKey = key; page.selectedEnglishName = englishName; page.selectedChineseName = chineseName }
                            }
                        }
                        AppText {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            visible: page.catalog && page.catalog.count === 0
                            text: AppController.connected ? page.t("没有匹配的条目", "No matching entries") : page.t("连接游戏后读取目录", "Connect to load the catalog")
                            color: Theme.color.onSurfaceVariantColor
                        }
                        ScrollBar { target: list; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }
                    }
                }
            }
            Card {
                Layout.preferredWidth: page.width < 850 ? 256 : 300
                Layout.fillHeight: true
                type: "filled"
                padding: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 14
                    AppText {
                        text: page.selectedKey ? (page.chinese ? page.selectedChineseName : page.selectedEnglishName) : page.t("未选择条目", "No Selection")
                        font.pixelSize: Theme.typography.titleLarge.size
                        color: Theme.color.onSurfaceColor
                        wrapMode: Text.WrapAnywhere
                        Layout.fillWidth: true
                    }
                    AppText {
                        text: page.selectedKey || page.t("从左侧选择目录项", "Select an entry on the left")
                        color: Theme.color.onSurfaceVariantColor
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        id: rarity
                        visible: page.secondaryAction !== ""
                        label: page.t("稀有度", "Rarity")
                        model: [
                            {text: page.t("普通", "Common"), value: "Common"},
                            {text: page.t("稀有", "Rare"), value: "Rare"},
                            {text: page.t("史诗", "Epic"), value: "Epic"},
                            {text: page.t("英雄", "Heroic"), value: "Heroic"},
                            {text: page.t("传奇", "Legendary"), value: "Legendary"}
                        ]
                        currentIndex: 0
                        Layout.fillWidth: true
                    }
                    Item { Layout.fillHeight: true }
                    Button {
                        enabled: AppController.connected && !AppController.busy && page.selectedKey !== ""
                        text: page.actionText
                        icon: "add_circle"
                        type: "filled"
                        Layout.fillWidth: true
                        onClicked: page.action === "weapon" ? AppController.selectWeapon(page.selectedKey) : AppController.spawn(page.action, page.selectedKey, rarity.currentValue)
                    }
                    Button {
                        visible: page.secondaryAction !== ""
                        enabled: AppController.connected && !AppController.busy && page.selectedKey !== ""
                        text: page.secondaryActionText
                        icon: "remove_circle"
                        type: "outlined"
                        Layout.fillWidth: true
                        onClicked: AppController.spawn(page.secondaryAction, page.selectedKey)
                    }
                    TextField {
                        id: objectId
                        visible: page.action === "spawn_consumable" || page.action === "spawn_loot"
                        label: page.t("待清理对象 ID", "Object ID to Clean")
                        text: AppController.lastObjectId > 0 ? String(AppController.lastObjectId) : ""
                        Layout.fillWidth: true
                    }
                    Button {
                        visible: objectId.visible
                        enabled: AppController.connected && !AppController.busy && Number(objectId.text) > 0
                        text: page.t("清理生成对象", "Clean Up Object")
                        type: "outlined"
                        Layout.fillWidth: true
                        onClicked: AppController.destroyObject(Number(objectId.text))
                    }
                }
            }
        }
    }
}
