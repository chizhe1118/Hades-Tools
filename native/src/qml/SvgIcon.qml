import QtQuick
import QtQuick.Effects
import md3.Core

Image {
    id: icon
    property color tint: Theme.color.onSurfaceVariantColor

    sourceSize.width: Math.ceil(width)
    sourceSize.height: Math.ceil(height)
    fillMode: Image.PreserveAspectFit
    layer.enabled: true
    layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: icon.tint
    }
}
