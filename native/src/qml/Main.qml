import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import md3.Core

Window {
    id: root
    width: 1280
    height: 820
    minimumWidth: 980
    minimumHeight: 640
    visible: true
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint
    title: "Hades Tools"
    color: Theme.color.background

    readonly property bool chinese: AppController.language === "zh"
    readonly property string bodyFamily: UiStyle.family
    property int currentIndex: 0
    property int requestedIndex: 0
    property string requestedLanguage: AppController.language
    readonly property int aboutIndex: navigation.length
    readonly property int settingsIndex: navigation.length + 1
    property var navigation: [
        {zh: "概览", en: "Overview", icon: "dashboard"},
        {zh: "功能", en: "Functions", icon: "tune"},
        {zh: "自身状态", en: "Player State", icon: "person"},
        {zh: "资源", en: "Resources", icon: "folder"},
        {zh: "道具", en: "Items", icon: "inventory_2"},
        {zh: "祝福", en: "Boons", icon: "auto_awesome"},
        {zh: "奖励", en: "Rewards", icon: "redeem"},
        {zh: "武器", en: "Weapons", icon: "sports_martial_arts"},
        {zh: "日志", en: "Logs", icon: "receipt_long"}
    ]

    function t(zh, en) { return chinese ? zh : en }

    // Tooltips are opened manually so they must be closed when the window loses focus.
    onActiveChanged: if (!active) {
        titleBar.closeTooltips()
        languageTooltip.close()
        settingsTooltip.close()
        aboutTooltip.close()
    }

    function navigate(index) {
        requestedIndex = index
        menu.reveal(index)
        if (!pageTransition.running && currentIndex !== requestedIndex) pageTransition.start()
    }

    function switchLanguage(language) {
        requestedLanguage = language
        if (!languageTransition.running && AppController.language !== language) languageTransition.start()
    }

    Component.onCompleted: StyleManager.isDarkTheme = AppController.darkTheme

    Connections {
        target: AppController
        function onAppearanceChanged() {
            StyleManager.isDarkTheme = AppController.darkTheme
        }
    }

    SequentialAnimation {
        id: languageTransition
        NumberAnimation { target: shell; property: "opacity"; to: 0; duration: AppController.reducedMotion ? 0 : 90; easing.type: Easing.InQuad }
        ScriptAction { script: AppController.setLanguage(root.requestedLanguage) }
        NumberAnimation { target: shell; property: "opacity"; to: 1; duration: AppController.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic }
        onFinished: if (root.requestedLanguage !== AppController.language) languageTransition.start()
    }

    SequentialAnimation {
        id: pageTransition
        ParallelAnimation {
            NumberAnimation { target: pages; property: "opacity"; to: 0; duration: AppController.reducedMotion ? 0 : 90; easing.type: Easing.InQuad }
            NumberAnimation { target: pageMotion; property: "x"; to: -10; duration: AppController.reducedMotion ? 0 : 90; easing.type: Easing.InQuad }
        }
        ScriptAction { script: { root.currentIndex = root.requestedIndex; pageMotion.x = 16 } }
        ParallelAnimation {
            NumberAnimation { target: pages; property: "opacity"; to: 1; duration: AppController.reducedMotion ? 0 : 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: pageMotion; property: "x"; to: 0; duration: AppController.reducedMotion ? 0 : 200; easing.type: Easing.OutCubic }
        }
        onFinished: if (root.requestedIndex !== root.currentIndex) pageTransition.start()
    }

    WindowTitleBar {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        window: root
        z: 100
    }

    WindowResizeHandles { anchors.fill: parent; window: root }

    RowLayout {
        id: shell
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 248
            color: Theme.color.surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                NavigationDrawer {
                    id: drawer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    modal: false
                    drawerWidth: 248
                    title: "Hades Tools"
                    Flickable {
                        id: menu
                        anchors.fill: parent
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: navigationColumn.implicitHeight
                        function reveal(index) {
                            if (index >= root.navigation.length) return
                            const top = index * 64
                            if (top < contentY) contentY = top
                            else if (top + 56 > contentY + height) contentY = top + 56 - height
                        }
                        Rectangle {
                            x: 12
                            y: Math.min(root.requestedIndex, root.navigation.length - 1) * 64
                            width: parent.width - 24
                            height: 56
                            radius: 28
                            color: Theme.color.secondaryContainer
                            opacity: root.requestedIndex < root.navigation.length ? 1 : 0
                            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                        }
                        Column {
                            id: navigationColumn
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: root.navigation
                                Button {
                                    id: navigationButton
                                    required property int index
                                    required property var modelData
                                    readonly property bool selected: root.requestedIndex === index
                                    width: parent.width - 24
                                    height: 56
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    type: "text"
                                    onClicked: root.navigate(index)
                                    contentItem: Item {
                                        implicitWidth: navigationButton.width - 32
                                        implicitHeight: 28
                                        Row {
                                            anchors.fill: parent
                                            spacing: 12
                                            AppText {
                                                text: navigationButton.modelData.icon
                                                width: 24
                                                height: 28
                                                verticalAlignment: Text.AlignVCenter
                                                font.family: Theme.iconFont.name
                                                font.weight: Font.Normal
                                                font.pixelSize: 24
                                                color: navigationButton.selected ? Theme.color.onSecondaryContainerColor : Theme.color.onSurfaceVariantColor
                                            }
                                            AppText {
                                                text: root.t(navigationButton.modelData.zh, navigationButton.modelData.en)
                                                height: 28
                                                verticalAlignment: Text.AlignVCenter
                                                color: navigationButton.selected ? Theme.color.onSecondaryContainerColor : Theme.color.onSurfaceVariantColor
                                                Behavior on color { ColorAnimation { duration: 160 } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        ScrollBar {
                            parent: menu
                            target: menu
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    color: Theme.color.surfaceContainer

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        height: 1
                        color: Theme.color.outlineVariant
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 8
                        IconButton {
                            id: languageButton
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            type: "standard"
                            Accessible.name: root.chinese ? "Switch to English" : "切换为中文"
                            onClicked: {
                                languageTooltip.close()
                                root.switchLanguage(root.requestedLanguage === "zh" ? "en" : "zh")
                            }
                            SvgIcon {
                                anchors.centerIn: parent
                                source: "assets/languages.svg"
                                sourceSize.width: 24
                                sourceSize.height: 24
                                width: 24
                                height: 24
                                tint: languageButton.hovered ? Theme.color.primary : Theme.color.onSurfaceVariantColor
                                opacity: languageButton.hovered ? 1 : 0.72
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }
                            onHoveredChanged: {
                                if (hovered) {
                                    const position = languageButton.mapToItem(root.contentItem, 0, 0)
                                    languageTooltip.x = position.x
                                    languageTooltip.y = position.y - languageTooltip.implicitHeight - 8
                                    languageTooltip.open()
                                } else languageTooltip.close()
                            }
                            ToolTip {
                                id: languageTooltip
                                parent: root.contentItem
                                text: languageButton.Accessible.name
                                timeout: 0
                            }
                        }
                        Item { Layout.fillWidth: true }
                        IconButton {
                            id: settingsButton
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            icon: "settings"
                            type: root.requestedIndex === root.settingsIndex ? "filledTonal" : "standard"
                            Accessible.name: root.t("设置", "Settings")
                            onClicked: {
                                settingsTooltip.close()
                                root.navigate(root.settingsIndex)
                            }
                            onHoveredChanged: {
                                if (hovered) {
                                    const position = settingsButton.mapToItem(root.contentItem, 0, 0)
                                    settingsTooltip.x = position.x + (settingsButton.width - settingsTooltip.implicitWidth) / 2
                                    settingsTooltip.y = position.y - settingsTooltip.implicitHeight - 8
                                    settingsTooltip.open()
                                } else settingsTooltip.close()
                            }
                            ToolTip {
                                id: settingsTooltip
                                parent: root.contentItem
                                text: root.t("设置", "Settings")
                                timeout: 0
                            }
                        }
                        IconButton {
                            id: aboutButton
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            type: root.requestedIndex === root.aboutIndex ? "filledTonal" : "standard"
                            Accessible.name: root.t("关于", "About")
                            onClicked: {
                                aboutTooltip.close()
                                root.navigate(root.aboutIndex)
                            }
                            SvgIcon {
                                anchors.centerIn: parent
                                source: "assets/circle-alert.svg"
                                sourceSize.width: 22
                                sourceSize.height: 22
                                width: 22
                                height: 22
                                tint: aboutButton.hovered ? Theme.color.primary : Theme.color.onSurfaceVariantColor
                                opacity: aboutButton.hovered ? 1 : 0.72
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }
                            onHoveredChanged: {
                                if (hovered) {
                                    const position = aboutButton.mapToItem(root.contentItem, 0, 0)
                                    aboutTooltip.x = position.x + (aboutButton.width - aboutTooltip.implicitWidth) / 2
                                    aboutTooltip.y = position.y - aboutTooltip.implicitHeight - 8
                                    aboutTooltip.open()
                                } else aboutTooltip.close()
                            }
                            ToolTip {
                                id: aboutTooltip
                                parent: root.contentItem
                                text: root.t("关于", "About")
                                timeout: 0
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.color.background

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                TopAppBar {
                    Layout.fillWidth: true
                    title: "Hades Tools"
                    showNavigationIcon: false
                    RowLayout {
                        spacing: 10
                        AppText {
                            text: AppController.connected && AppController.lastUpdated
                                  ? root.t("更新 " + AppController.lastUpdated.slice(11), "Updated " + AppController.lastUpdated.slice(11))
                                  : root.t("等待状态", "Waiting for state")
                            color: Theme.color.onSurfaceVariantColor
                            font.pixelSize: Theme.typography.labelMedium.size
                            verticalAlignment: Text.AlignVCenter
                        }
                        IconButton {
                            icon: "refresh"
                            type: "standard"
                            onClicked: AppController.refresh()
                            enabled: AppController.connected && !AppController.busy
                        }
                        Button {
                            text: AppController.busy
                                  ? root.t("处理中…", "Working…")
                                  : (AppController.connected ? root.t("重新连接", "Reconnect") : root.t("连接游戏", "Connect"))
                            type: "filledTonal"
                            enabled: !AppController.busy
                            onClicked: AppController.connectToGame()
                        }
                        AppText {
                            text: AppController.connected ? root.t("在线", "Online") : root.t("离线", "Offline")
                            color: AppController.connected ? Theme.color.primary : Theme.color.error
                            font.pixelSize: Theme.typography.labelLarge.size
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    StackLayout {
                        id: pages
                        anchors.fill: parent
                        transform: Translate { id: pageMotion }
                        currentIndex: root.currentIndex
                        OverviewPage {}
                        FunctionsPage {}
                        PlayerStatePage {}
                        ResourcesPage {}
                        CatalogPage {
                            title: root.t("道具目录", "Item Catalog")
                            subtitle: root.t("玩家附近生成", "Spawn near player")
                            catalog: AppController.consumablesCatalog
                            action: "spawn_consumable"
                            actionText: root.t("生成道具", "Spawn Item")
                        }
                        CatalogPage {
                            title: root.t("祝福目录", "Boon Catalog")
                            subtitle: root.t("当前祝福", "Current boons")
                            catalog: AppController.traitsCatalog
                            action: "add_trait"
                            actionText: root.t("添加祝福", "Add Boon")
                            secondaryAction: "remove_trait"
                            secondaryActionText: root.t("移除祝福", "Remove Boon")
                        }
                        CatalogPage {
                            title: root.t("神祇奖励", "God Rewards")
                            subtitle: root.t("生成与清理", "Spawn and clean up")
                            catalog: AppController.lootCatalog
                            action: "spawn_loot"
                            actionText: root.t("生成奖励", "Spawn Reward")
                        }
                        CatalogPage {
                            title: root.t("武器", "Weapons")
                            subtitle: root.t("英雄武器", "Hero weapons")
                            catalog: AppController.weaponsCatalog
                            action: "weapon"
                            actionText: root.t("装备武器", "Equip Weapon")
                        }
                        LogsPage {}
                        AboutPage {}
                        SettingsPage {}
                    }
                    MouseArea {
                        anchors.fill: parent
                        visible: pageTransition.running || languageTransition.running
                        acceptedButtons: Qt.AllButtons
                        onWheel: function(wheel) { wheel.accepted = true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(44, statusText.implicitHeight + 20)
                    color: AppController.hasError ? Theme.color.errorContainer : Theme.color.surfaceContainer
                    AppText {
                        id: statusText
                        anchors.fill: parent
                        anchors.margins: 10
                        text: AppController.status
                        color: AppController.hasError ? Theme.color.onErrorContainerColor : Theme.color.onSurfaceVariantColor
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
