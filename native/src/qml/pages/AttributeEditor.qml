import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import md3.Core

RowLayout {
    id: editor
    property string label
    property string icon
    property var liveValue
    signal submitted(double value)

    spacing: 10
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.minimumWidth: 0
    enabled: AppController.connected && !AppController.busy
    onVisibleChanged: if (!visible) applyTooltip.close()

    LiveNumberField {
        id: input
        label: editor.label
        leadingIcon: editor.icon
        liveValue: editor.liveValue
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        onAccepted: editor.submitted(Number(text))
    }
    IconButton {
        id: applyButton
        icon: "check"
        type: "filledTonal"
        Accessible.name: (AppController.language === "zh" ? "应用" : "Apply ") + editor.label
        onClicked: editor.submitted(Number(input.text))
        onHoveredChanged: hovered ? applyTooltip.open() : applyTooltip.close()
        ToolTip {
            id: applyTooltip
            parent: input
            text: applyButton.Accessible.name
            y: -implicitHeight - 8
            x: input.width - implicitWidth
            timeout: 0
        }
    }

    Connections {
        target: Window.window
        function onActiveChanged() {
            if (!Window.window || !Window.window.active) applyTooltip.close()
        }
    }
}
