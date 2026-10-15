import QtQuick
import QtQuick.Layouts
import md3.Core

Card {
    id: card
    default property alias body: bodyLayout.data
    property alias spacing: bodyLayout.spacing

    type: "outlined"
    padding: 20
    implicitHeight: bodyLayout.implicitHeight + padding * 2

    contentItem: ColumnLayout {
        id: bodyLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16
    }
}
