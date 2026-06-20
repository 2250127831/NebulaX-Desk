import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    required property int orderId
    required property string side
    required property int price
    required property int qty
    required property string status
    required property string timeStr
    property int filledQty: 0
    property bool checkable: false
    property bool checked: false
    property bool multiSelectMode: false

    signal cancelRequested(int orderId)
    signal longPressed()

    implicitHeight: 56
    radius: 6
    color: {
        if (!root.ListView.view) return "#f5f5f5"
        if (checked) return "#e3f2fd"
        if (status === "FILLED" || status === "CANCELLED") return "#fafafa"
        return "#ffffff"
    }
    border.color: checked ? "#2196F3" : "#e0e0e0"
    border.width: checked ? 2 : 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // 多选勾选框
        CheckBox {
            visible: root.multiSelectMode && (status === "OPEN" || status === "PARTIALLY_FILLED")
            checked: root.checked
            opacity: root.multiSelectMode ? 1 : 0
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Label { text: "#" + root.orderId; font.bold: true; font.pixelSize: 13 }
                Label {
                    text: root.side
                    color: root.side === "BUY" ? "#F44336" : "#4CAF50"
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: root.status
                    color: root.status === "OPEN" ? "#FF9800" : "#9E9E9E"
                    font.pixelSize: 12
                }
            }

            RowLayout {
                Label { text: root.price + " × " + root.qty; font.pixelSize: 12; color: "#666" }
                Label {
                    text: root.filledQty > 0 ? "已成交 " + root.filledQty : ""
                    font.pixelSize: 11
                    color: "#4CAF50"
                    visible: root.filledQty > 0
                }
                Item { Layout.fillWidth: true }
                Label { text: root.timeStr; font.pixelSize: 11; color: "#999" }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            } else if (root.multiSelectMode) {
                root.checked = !root.checked
            }
        }

        onPressAndHold: {
            if (!root.multiSelectMode) {
                root.checked = true
                root.longPressed()
            }
        }

        Menu {
            id: contextMenu
            MenuItem {
                text: "撤单"
                enabled: status === "OPEN" || status === "PARTIALLY_FILLED"
                onTriggered: root.cancelRequested(orderId)
            }
            MenuItem {
                text: "复制 ID"
                onTriggered: {
                    // 使用 Clipboard API
                }
            }
        }
    }
}
