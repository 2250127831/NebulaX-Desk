import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

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

    implicitHeight: 52
    radius: Theme.radiusMd
    color: {
        if (checked) return Qt.rgba(0.18, 0.2, 0.3, 1)
        if (status === "FILLED" || status === "CANCELLED") return Qt.rgba(0.12, 0.12, 0.16, 1)
        return Theme.bgCard
    }
    border.color: checked ? Theme.accent : Theme.borderLight
    border.width: checked ? 1.5 : 1

    // Status color strip on the left
    Rectangle {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 3; radius: 1
        color: {
            switch (status) {
            case "OPEN":              return Theme.statusOpen
            case "PARTIALLY_FILLED":  return Theme.statusPartial
            case "FILLED":            return Theme.statusFilled
            case "CANCELLED":         return Theme.statusCancel
            default:                  return Theme.textMuted
            }
        }
        anchors.topMargin: 4; anchors.bottomMargin: 4; anchors.leftMargin: 2

        // Breathing glow on OPEN orders
        SequentialAnimation on color {
            loops: Animation.Infinite
            running: status === "OPEN"
            ColorAnimation { from: Theme.statusOpen; to: Qt.lighter(Theme.statusOpen, 1.4); duration: Theme.animBreath; easing.type: Easing.InOutSine }
            ColorAnimation { from: Qt.lighter(Theme.statusOpen, 1.4); to: Theme.statusOpen; duration: Theme.animBreath; easing.type: Easing.InOutSine }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 12
        anchors.topMargin: 8; anchors.bottomMargin: 8
        spacing: 8

        // Multi-select checkbox
        CheckBox {
            visible: root.multiSelectMode
            checked: root.checked
            onCheckedChanged: if (root.multiSelectMode) root.checked = checked
        }

        // Main content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 6
                Label {
                    text: "#" + root.orderId
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMd
                    color: Theme.textPrimary
                    font.family: Theme.fontMono
                }
                Label {
                    text: root.side
                    color: root.side === "BUY" ? Theme.buyGreen : Theme.sellRed
                    font.bold: true
                    font.pixelSize: Theme.fontSizeSm
                }
                Item { Layout.fillWidth: true }
                // Status badge
                Rectangle {
                    height: 18
                    radius: 9
                    color: {
                        switch (status) {
                        case "OPEN":              return Qt.rgba(0.94, 0.72, 0.04, 0.15)
                        case "PARTIALLY_FILLED":  return Qt.rgba(0.18, 0.58, 0.95, 0.15)
                        case "FILLED":            return Qt.rgba(0.05, 0.80, 0.51, 0.15)
                        case "CANCELLED":         return Qt.rgba(0.52, 0.56, 0.61, 0.15)
                        default:                  return Qt.rgba(0.52, 0.56, 0.61, 0.15)
                        }
                    }
                    Label {
                        anchors.centerIn: parent
                        text: {
                            switch (status) {
                            case "OPEN":              return "OPEN"
                            case "PARTIALLY_FILLED":  return "PARTIAL"
                            case "FILLED":            return "FILLED"
                            case "CANCELLED":         return "CANCEL"
                            default:                  return status
                            }
                        }
                        font.pixelSize: Theme.fontSizeXs
                        color: {
                            switch (status) {
                            case "OPEN":              return Theme.statusOpen
                            case "PARTIALLY_FILLED":  return Theme.statusPartial
                            case "FILLED":            return Theme.statusFilled
                            case "CANCELLED":         return Theme.statusCancel
                            default:                  return Theme.textMuted
                            }
                        }
                        font.bold: true
                        leftPadding: 8; rightPadding: 8
                    }
                }
                Label {
                    text: root.timeStr
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.textMuted
                }
            }

            RowLayout {
                spacing: 8
                Label {
                    text: root.price + " × " + root.qty
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.textSecondary
                    font.family: Theme.fontMono
                }
                // Filled progress
                Rectangle {
                    visible: root.filledQty > 0
                    width: 60; height: 4; radius: 2
                    color: Theme.bgDeep
                    Rectangle {
                        width: parent.width * Math.min(root.filledQty / root.qty, 1)
                        height: parent.height; radius: 2
                        color: root.filledQty >= root.qty ? Theme.buyGreen : Theme.statusPartial
                        Behavior on width { NumberAnimation { duration: Theme.animNorm } }
                    }
                }
                Label {
                    visible: root.filledQty > 0
                    text: root.filledQty + "/" + root.qty
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.textMuted
                    font.family: Theme.fontMono
                }
                Item { Layout.fillWidth: true }
            }
        }
    }

    // Hover effect
    Rectangle {
        anchors.fill: parent; radius: Theme.radiusMd
        color: Qt.rgba(1, 1, 1, 0.03)
        visible: mouseArea.containsMouse && !checked
        Behavior on visible { NumberAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
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
            background: Rectangle {
                color: Theme.bgElevated; radius: Theme.radiusSm
                border.color: Theme.borderLight; border.width: 1
            }
            MenuItem {
                text: "撤单"
                enabled: status === "OPEN" || status === "PARTIALLY_FILLED"
                onTriggered: root.cancelRequested(orderId)
                contentItem: Label {
                    text: "撤单"
                    color: enabled ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: Theme.fontSizeSm
                }
                background: Rectangle {
                    color: parent.highlighted ? Theme.bgHover : "transparent"
                }
            }
            MenuItem {
                text: "复制 ID"
                onTriggered: {}
                contentItem: Label {
                    text: "复制 ID"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSm
                }
                background: Rectangle {
                    color: parent.highlighted ? Theme.bgHover : "transparent"
                }
            }
        }
    }
}
