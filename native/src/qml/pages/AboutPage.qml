import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    readonly property bool chinese: AppController.language === "zh"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18
        AppText {
            text: chinese ? "关于" : "About"
            font.pixelSize: Theme.typography.headlineSmall.size
            color: Theme.color.onSurfaceColor
        }
        Card {
            Layout.fillWidth: true
            Layout.preferredHeight: 216
            type: "outlined"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16
                Image {
                    source: "../assets/circle-alert.svg"
                    sourceSize.width: 32
                    sourceSize.height: 32
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                }
                AppText {
                    text: "Hades Tools"
                    font.pixelSize: Theme.typography.titleLarge.size
                    color: Theme.color.onSurfaceColor
                }
                AppText {
                    text: chinese ? "Hades 工具" : "Hades Tools"
                    color: Theme.color.onSurfaceVariantColor
                }
                AppText {
                    text: chinese ? "作者：ChiZhe&ChatGPT" : "Author: ChiZhe&ChatGPT"
                    font.pixelSize: Theme.typography.titleMedium.size
                    color: Theme.color.primary
                }
                AppText {
                    text: (chinese ? "版本 " : "Version ") + Qt.application.version
                    color: Theme.color.onSurfaceVariantColor
                }
                Item { Layout.fillHeight: true }
            }
        }
        Card {
            Layout.fillWidth: true
            type: "outlined"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10
                AppText {
                    text: chinese ? "界面技术" : "Interface technology"
                    font.pixelSize: Theme.typography.titleMedium.size
                    color: Theme.color.onSurfaceColor
                }
                AppText {
                    text: "C++ · Qt Quick · Material Components QML"
                    color: Theme.color.onSurfaceVariantColor
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
