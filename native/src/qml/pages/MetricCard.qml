import QtQuick
import QtQuick.Layouts
import md3.Core

SectionCard {
    id: card
    property string label
    property string value
    property string icon
    property string detail

    type: "filled"
    padding: 16
    spacing: 8
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.minimumWidth: 0

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        AppText {
            text: card.icon
            font.family: Theme.iconFont.name
            font.weight: Font.Normal
            font.pixelSize: 24
            color: Theme.color.primary
        }
        AppText {
            text: card.label
            Layout.fillWidth: true
            color: Theme.color.onSurfaceVariantColor
            elide: Text.ElideRight
        }
    }
    AppText {
        text: card.value
        font.pixelSize: 28
        color: Theme.color.onSurfaceColor
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
    AppText {
        text: card.detail
        font.pixelSize: 12
        color: Theme.color.onSurfaceVariantColor
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
}
