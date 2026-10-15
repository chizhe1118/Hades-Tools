import QtQuick
import md3.Core

TextField {
    id: field
    property var liveValue

    function syncFromGame() {
        if (focused) return
        const next = liveValue === undefined || liveValue === null ? "" : String(liveValue)
        if (text !== next) text = next
    }

    onLiveValueChanged: syncFromGame()
    Component.onCompleted: syncFromGame()
}
