import QtQuick
import QtQuick.Window

Item {
    id: frame
    required property var window
    visible: window.visibility !== Window.Maximized && window.visibility !== Window.FullScreen
    z: 1000
    Repeater {
        model: [
            {edges: Qt.LeftEdge, x: 0, y: 8, w: 5, h: frame.height - 16, cursor: Qt.SizeHorCursor},
            {edges: Qt.RightEdge, x: frame.width - 5, y: 8, w: 5, h: frame.height - 16, cursor: Qt.SizeHorCursor},
            {edges: Qt.TopEdge, x: 8, y: 0, w: frame.width - 16, h: 5, cursor: Qt.SizeVerCursor},
            {edges: Qt.BottomEdge, x: 8, y: frame.height - 5, w: frame.width - 16, h: 5, cursor: Qt.SizeVerCursor},
            {edges: Qt.TopEdge | Qt.LeftEdge, x: 0, y: 0, w: 8, h: 8, cursor: Qt.SizeFDiagCursor},
            {edges: Qt.TopEdge | Qt.RightEdge, x: frame.width - 8, y: 0, w: 8, h: 8, cursor: Qt.SizeBDiagCursor},
            {edges: Qt.BottomEdge | Qt.LeftEdge, x: 0, y: frame.height - 8, w: 8, h: 8, cursor: Qt.SizeBDiagCursor},
            {edges: Qt.BottomEdge | Qt.RightEdge, x: frame.width - 8, y: frame.height - 8, w: 8, h: 8, cursor: Qt.SizeFDiagCursor}
        ]
        MouseArea {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: modelData.w
            height: modelData.h
            cursorShape: modelData.cursor
            onPressed: frame.window.startSystemResize(modelData.edges)
        }
    }
}
