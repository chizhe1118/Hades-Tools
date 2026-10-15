import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import md3.Core

Rectangle {
    id: bar
    required property var window
    readonly property bool maximized: window.visibility === Window.Maximized
    readonly property bool chinese: AppController.language === "zh"
    implicitHeight: 40
    color: Theme.color.surfaceContainer
    onWidthChanged: titleTooltip.close()
    onMaximizedChanged: titleTooltip.close()

    function closeTooltips() { titleTooltip.close() }

    Connections {
        target: bar.window
        function onActiveChanged() { if (!bar.window.active) bar.closeTooltips() }
    }

    function toggleMaximized() {
        if (maximized) window.showNormal()
        else window.showMaximized()
    }

    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: 144
        acceptedButtons: Qt.LeftButton
        onPressed: bar.window.startSystemMove()
        onDoubleClicked: bar.toggleMaximized()
    }

    AppText {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        text: "Hades Tools"
        font.pixelSize: 13
        color: Theme.color.onSurfaceVariantColor
    }
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: [
                {icon: "remove", label: bar.chinese ? "最小化" : "Minimize", action: "minimize"},
                {icon: bar.maximized ? "filter_none" : "crop_square", label: bar.maximized ? (bar.chinese ? "还原窗口" : "Restore") : (bar.chinese ? "最大化" : "Maximize"), action: "maximize"},
                {icon: "close", label: bar.chinese ? "关闭" : "Close", action: "close"}
            ]
            IconButton {
                id: control
                required property var modelData
                width: 48
                height: 36
                icon: modelData.icon
                Accessible.name: modelData.label
                contentColor: modelData.action === "close" && hovered ? Theme.color.error : Theme.color.onSurfaceVariantColor
                onClicked: {
                    hoverDelay.stop()
                    titleTooltip.close()
                    if (modelData.action === "minimize") bar.window.showMinimized()
                    else if (modelData.action === "maximize") bar.toggleMaximized()
                    else bar.window.close()
                }
                onHoveredChanged: {
                    if (hovered) hoverDelay.restart()
                    else { hoverDelay.stop(); titleTooltip.close() }
                }
                Timer {
                    id: hoverDelay
                    interval: 400
                    onTriggered: {
                        if (!control.hovered) return
                        const position = control.mapToItem(bar, 0, 0)
                        titleTooltip.text = control.modelData.label
                        titleTooltip.x = Math.max(4, Math.min(position.x, bar.width - titleTooltip.implicitWidth - 4))
                        titleTooltip.y = bar.height + 4
                        titleTooltip.open()
                    }
                }
            }
        }
    }
    ToolTip { id: titleTooltip; timeout: 0 }
}
