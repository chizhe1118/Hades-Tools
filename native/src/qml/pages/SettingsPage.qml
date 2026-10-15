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
    function t(zh, en) { return chinese ? zh : en }

    ColumnLayout {
        id: content
        width: Math.min(page.width - 48, 1000)
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        spacing: 18

        AppText {
            text: page.t("设置", "Settings")
            font.pixelSize: Theme.typography.headlineSmall.size
            color: Theme.color.onSurfaceColor
        }
        AppText {
            text: page.t("外观、动画和状态刷新设置会自动保存。",
                         "Appearance, motion and live refresh preferences are saved automatically.")
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.color.onSurfaceVariantColor
        }

        SectionCard {
            Layout.fillWidth: true
            AppText {
                text: page.t("主题", "Theme")
                font.pixelSize: Theme.typography.titleLarge.size
                color: Theme.color.onSurfaceColor
            }
            GridLayout {
                Layout.fillWidth: true
                columns: page.width >= 760 ? 3 : 1
                columnSpacing: 12
                rowSpacing: 12
                ThemeChoice { mode: "light"; label: page.t("亮色", "Light"); symbol: "light_mode" }
                ThemeChoice { mode: "dark"; label: page.t("暗色", "Dark"); symbol: "dark_mode" }
                ThemeChoice { mode: "system"; label: page.t("跟随系统", "System"); symbol: "desktop_windows" }
            }
        }

        SectionCard {
            Layout.fillWidth: true
            AppText {
                text: page.t("动画", "Motion")
                font.pixelSize: Theme.typography.titleLarge.size
                color: Theme.color.onSurfaceColor
            }
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    AppText {
                        text: page.t("减弱动画", "Reduced motion")
                        color: Theme.color.onSurfaceColor
                    }
                    AppText {
                        text: page.t("关闭页面滑动、淡入淡出和主题卡片缩放。",
                                     "Disable page transitions, fades and theme-card scaling.")
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: Theme.color.onSurfaceVariantColor
                    }
                }
                Switch {
                    checked: AppController.reducedMotion
                    Accessible.name: page.t("减弱动画", "Reduced motion")
                    onClicked: AppController.setReducedMotion(checked)
                }
            }
        }

        SectionCard {
            Layout.fillWidth: true
            AppText {
                text: page.t("游戏状态刷新", "Live game state")
                font.pixelSize: Theme.typography.titleLarge.size
                color: Theme.color.onSurfaceColor
            }
            RowLayout {
                Layout.fillWidth: true
                AppText {
                    text: page.t("自动刷新", "Automatic refresh")
                    Layout.fillWidth: true
                    color: Theme.color.onSurfaceColor
                }
                Switch {
                    checked: AppController.autoRefresh
                    Accessible.name: page.t("自动刷新", "Automatic refresh")
                    onClicked: AppController.setAutoRefresh(checked)
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [500, 1000, 2000, 5000]
                    Button {
                        required property int modelData
                        text: String(modelData / 1000) + page.t(" 秒", " s")
                        type: AppController.refreshInterval === modelData ? "filledTonal" : "outlined"
                        enabled: AppController.autoRefresh
                        onClicked: AppController.setRefreshInterval(modelData)
                    }
                }
            }
            AppText {
                text: page.t("只调整读取频率，不会自动执行属性修改。",
                             "This changes read frequency; it does not apply attribute changes automatically.")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.color.onSurfaceVariantColor
            }
        }

        SectionCard {
            Layout.fillWidth: true
            AppText {
                text: page.t("语言与字体", "Language and typography")
                font.pixelSize: Theme.typography.titleLarge.size
                color: Theme.color.onSurfaceColor
            }
            AppText {
                text: page.t("左下角语言图标切换界面语言。中文使用宋体加粗，英文使用 Segoe UI。",
                             "Use the bottom-left language icon to switch. Chinese uses bold SimSun; English uses Segoe UI.")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.color.onSurfaceVariantColor
            }
        }
    }

    ScrollBar {
        parent: page
        target: page
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }
}
