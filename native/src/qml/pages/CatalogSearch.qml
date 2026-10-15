import QtQuick
import QtQuick.Layouts
import md3.Core

RowLayout {
    id: search
    required property var catalog
    readonly property bool chinese: AppController.language === "zh"
    Layout.fillWidth: true
    spacing: 10

    function applySearch() {
        if (catalog) catalog.filterText = input.text
    }
    TextField {
        id: input
        label: search.chinese ? "搜索名称或原始键" : "Search name or key"
        leadingIcon: "search"
        trailingIcon: text.length > 0 ? "close" : ""
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        onAccepted: search.applySearch()
        onTextChanged: if (text.length === 0) search.applySearch()
        onTrailingIconClicked: { text = ""; search.applySearch() }
    }
    Button {
        icon: "search"
        text: search.chinese ? "搜索" : "Search"
        type: "filledTonal"
        horizontalPadding: 16
        onClicked: search.applySearch()
    }
}
