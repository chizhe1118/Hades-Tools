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
    onChineseChanged: contentY = 0
    onVisibleChanged: if (visible) contentY = 0
    function t(zh, en) { return chinese ? zh : en }

    ColumnLayout {
        id: content
        width: Math.min(page.width - 48, 1120)
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        spacing: 18
        AppText { text: page.t("资源管理", "Resources"); font.pixelSize: Theme.typography.headlineSmall.size; color: Theme.color.onSurfaceColor }
        CatalogSearch { catalog: AppController.resourcesCatalog }
        AppText {
            text: page.t(AppController.resourcesCatalog.count + " 类资源", AppController.resourcesCatalog.count + " resource types")
                  + (AppController.lastUpdated ? "  ·  " + AppController.lastUpdated : "")
            color: Theme.color.onSurfaceVariantColor
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        AppText {
            visible: AppController.resourcesCatalog.count === 0
            text: AppController.connected ? page.t("没有匹配的资源", "No matching resources") : page.t("连接游戏后读取资源", "Connect to load resources")
            color: Theme.color.onSurfaceVariantColor
        }
        GridLayout {
            Layout.fillWidth: true
            columns: page.width > 850 ? 3 : 1
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: AppController.resourcesCatalog
                delegate: SectionCard {
                    required property string key
                    required property string chineseName
                    required property string englishName
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    padding: 16
                    spacing: 10
                    AppText { text: page.chinese ? chineseName : englishName; color: Theme.color.onSurfaceColor; elide: Text.ElideRight; Layout.fillWidth: true }
                    AppText { text: key; color: Theme.color.onSurfaceVariantColor; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                    AppText { text: String(AppController.resources[key] ?? "—"); font.pixelSize: Theme.typography.titleLarge.size; color: Theme.color.primary }
                    RowLayout {
                        Layout.fillWidth: true
                        enabled: AppController.connected && !AppController.busy
                        TextField { id: amount; label: page.t("数量", "Amount"); text: "9999"; Layout.fillWidth: true; Layout.minimumWidth: 0; onAccepted: AppController.setResource(key, Number(text)) }
                        IconButton { icon: "save"; type: "filled"; Accessible.name: page.t("应用数量", "Apply Amount"); onClicked: AppController.setResource(key, Number(amount.text)) }
                    }
                }
            }
        }
    }
    ScrollBar { parent: page; target: page; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }
}
