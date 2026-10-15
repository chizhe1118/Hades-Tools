import QtQuick
import QtQuick.Layouts
import md3.Core

Rectangle {
    id: choice
    required property string mode
    required property string label
    required property string symbol

    readonly property bool selected: AppController.themeMode === mode
    readonly property bool previewDark: mode === "dark"
        || (mode === "system" && AppController.darkTheme)

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitHeight: 156
    radius: 18
    color: selected ? Theme.color.secondaryContainer : Theme.color.surfaceContainer
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.color.primary : Theme.color.outlineVariant
    activeFocusOnTab: true
    Accessible.role: Accessible.RadioButton
    Accessible.name: label
    Accessible.checked: selected

    function select() {
        forceActiveFocus()
        AppController.setThemeMode(mode)
    }

    Keys.onSpacePressed: select()
    Keys.onReturnPressed: select()

    TapHandler { onTapped: choice.select() }
    HoverHandler { id: hover }

    scale: hover.hovered ? 1.015 : 1
    Behavior on scale {
        NumberAnimation {
            duration: AppController.reducedMotion ? 0 : 150
            easing.type: Easing.OutCubic
        }
    }
    Behavior on color { ColorAnimation { duration: AppController.reducedMotion ? 0 : 180 } }
    Behavior on border.color { ColorAnimation { duration: AppController.reducedMotion ? 0 : 180 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: choice.previewDark ? "#18171c" : "#f6f3fa"

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 8
                width: 26
                radius: 7
                color: choice.previewDark ? "#343039" : "#e7e0ec"
            }
            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 42
                anchors.rightMargin: 10
                anchors.topMargin: 12
                spacing: 8
                Rectangle {
                    width: parent.width * 0.62
                    height: 8
                    radius: 4
                    color: choice.previewDark ? "#cdc2db" : "#675080"
                }
                Rectangle {
                    width: parent.width
                    height: 26
                    radius: 8
                    color: choice.previewDark ? "#39343f" : "#e9e2f0"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            AppText {
                text: choice.symbol
                font.family: Theme.iconFont.name
                font.pixelSize: 21
                color: Theme.color.primary
            }
            AppText {
                text: choice.label
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Theme.color.onSurfaceColor
            }
            AppText {
                text: choice.selected ? "check_circle" : ""
                font.family: Theme.iconFont.name
                font.pixelSize: 19
                color: Theme.color.primary
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 22
        color: "transparent"
        border.width: 2
        border.color: Theme.color.primary
        visible: choice.activeFocus
    }
}
