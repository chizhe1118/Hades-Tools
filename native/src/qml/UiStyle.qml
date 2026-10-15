pragma Singleton
import QtQuick
import md3.Core

QtObject {
    readonly property bool chinese: AppController.language === "zh"
    readonly property string family: chinese ? "SimSun" : "Segoe UI"
    readonly property int weight: chinese ? Font.Bold : Font.Normal

    function applyTypography() {
        const roles = ["displayLarge", "displayMedium", "displaySmall", "headlineLarge",
            "headlineMedium", "headlineSmall", "titleLarge", "titleMedium", "titleSmall",
            "labelLarge", "labelMedium", "labelSmall", "bodyLarge", "bodyMedium", "bodySmall"]
        for (const role of roles) {
            Theme.typography[role].family = family
            Theme.typography[role].weight = chinese ? Font.Bold
                : (role.startsWith("label") || role === "titleMedium" || role === "titleSmall" ? Font.Medium : Font.Normal)
        }
    }

    onFamilyChanged: applyTypography()
    Component.onCompleted: applyTypography()
}
