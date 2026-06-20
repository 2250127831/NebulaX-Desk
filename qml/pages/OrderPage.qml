import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    id: root
    background: null
    padding: 0

    header: Rectangle {
        height: 36; color: "#0A0A0E"
        Label {
            anchors.left: parent.left; anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Place Order"; font.bold: true; font.pixelSize: Theme.fontSizeMd
            color: Theme.textPrimary
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        Frame {
            Layout.fillWidth: true; Layout.fillHeight: true; padding: 0
            background: Rectangle {
                color: Theme.bgCard; radius: Theme.radiusMd
                border.color: Theme.borderLight; border.width: 1
            }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.spacingLg; anchors.bottomMargin: 0; spacing: Theme.spacingMd

                RowLayout {
                    spacing: Theme.spacingSm
                    ButtonGroup { id: sideGroup }
                    Button {
                        id: buyBtn; text: "Buy"
                        checkable: true; checked: true
                        ButtonGroup.group: sideGroup
                        font.pixelSize: Theme.fontSizeMd; font.bold: true
                        contentItem: Label {
                            text: "Buy"
                            color: buyBtn.checked ? "#FFFFFF" : Theme.buyGreen
                            font.bold: true; font.pixelSize: Theme.fontSizeMd
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: buyBtn.checked
                                ? (buyBtn.down ? Qt.rgba(0.05,0.70,0.40,1) : buyBtn.hovered ? Qt.rgba(0.10,0.85,0.55,1) : Theme.buyGreen)
                                : (buyBtn.down ? Qt.rgba(0.05,0.80,0.51,0.25) : buyBtn.hovered ? Qt.rgba(0.05,0.80,0.51,0.12) : Theme.bgDeep)
                            border.color: buyBtn.checked ? Theme.buyGreen : (buyBtn.hovered ? Qt.rgba(0.05,0.80,0.51,0.4) : Theme.borderLight)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }
                        Layout.preferredWidth: 80
                    }
                    Button {
                        id: sellBtn; text: "Sell"
                        checkable: true
                        ButtonGroup.group: sideGroup
                        font.pixelSize: Theme.fontSizeMd; font.bold: true
                        contentItem: Label {
                            text: "Sell"
                            color: sellBtn.checked ? "#FFFFFF" : Theme.sellRed
                            font.bold: true; font.pixelSize: Theme.fontSizeMd
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: sellBtn.checked
                                ? (sellBtn.down ? Qt.rgba(0.85,0.20,0.30,1) : sellBtn.hovered ? Qt.rgba(0.90,0.30,0.40,1) : Theme.sellRed)
                                : (sellBtn.down ? Qt.rgba(0.96,0.27,0.36,0.25) : sellBtn.hovered ? Qt.rgba(0.96,0.27,0.36,0.12) : Theme.bgDeep)
                            border.color: sellBtn.checked ? Theme.sellRed : (sellBtn.hovered ? Qt.rgba(0.96,0.27,0.36,0.4) : Theme.borderLight)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }
                        Layout.preferredWidth: 80
                    }
                }

                Label { text: "Price"; font.pixelSize: Theme.fontSizeXs; color: Theme.textSecondary }
                TextField {
                    id: priceField; placeholderText: "0"
                    validator: IntValidator { bottom: 1 }
                    Layout.fillWidth: true; font.family: Theme.fontMono; font.pixelSize: Theme.fontSizeLg
                    color: Theme.textPrimary
                    leftPadding: 12; rightPadding: 12; topPadding: 8; bottomPadding: 8
                    placeholderTextColor: Theme.textMuted
                    background: Rectangle {
                        color: Theme.bgDeep; radius: Theme.radiusSm
                        border.color: parent.activeFocus ? Theme.borderFocus : Theme.borderLight; border.width: 1
                    }
                }

                Label { text: "Quantity"; font.pixelSize: Theme.fontSizeXs; color: Theme.textSecondary }
                TextField {
                    id: qtyField; placeholderText: "0"
                    validator: IntValidator { bottom: 1 }
                    Layout.fillWidth: true; font.family: Theme.fontMono; font.pixelSize: Theme.fontSizeLg
                    color: Theme.textPrimary
                    leftPadding: 12; rightPadding: 12; topPadding: 8; bottomPadding: 8
                    placeholderTextColor: Theme.textMuted
                    background: Rectangle {
                        color: Theme.bgDeep; radius: Theme.radiusSm
                        border.color: parent.activeFocus ? Theme.borderFocus : Theme.borderLight; border.width: 1
                    }
                }

                Label { text: "User ID"; font.pixelSize: Theme.fontSizeXs; color: Theme.textSecondary }
                TextField {
                    id: uidField; placeholderText: "0"
                    validator: IntValidator { bottom: 1 }
                    Layout.fillWidth: true; font.family: Theme.fontMono; font.pixelSize: Theme.fontSizeLg
                    color: Theme.textPrimary
                    leftPadding: 12; rightPadding: 12; topPadding: 8; bottomPadding: 8
                    placeholderTextColor: Theme.textMuted
                    background: Rectangle {
                        color: Theme.bgDeep; radius: Theme.radiusSm
                        border.color: parent.activeFocus ? Theme.borderFocus : Theme.borderLight; border.width: 1
                    }
                }

                Button {
                    id: sendBtn
                    text: "Send Order"
                    enabled: ClientWorker.connected && priceField.text.length > 0 && qtyField.text.length > 0 && uidField.text.length > 0
                    Layout.fillWidth: true; Layout.topMargin: Theme.spacingSm;                     font.bold: true; font.pixelSize: Theme.fontSizeMd
                    onClicked: {
                        ClientWorker.sendNewOrder(
                            buyBtn.checked ? 1 : 2,
                            parseInt(priceField.text), parseInt(qtyField.text), parseInt(uidField.text))
                    }
                    contentItem: Label {
                        text: "Send Order"; color: "#FFFFFF"
                        font.bold: true; font.pixelSize: Theme.fontSizeMd
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: {
                            if (!parent.enabled) { var c = buyBtn.checked ? Theme.buyGreen : Theme.sellRed; return Qt.rgba(c.r, c.g, c.b, 0.4) }
                            if (parent.down) return buyBtn.checked ? Qt.rgba(0.05,0.70,0.40,1) : Qt.rgba(0.85,0.20,0.30,1)
                            if (parent.hovered) return buyBtn.checked ? Qt.rgba(0.10,0.85,0.55,1) : Qt.rgba(0.90,0.30,0.40,1)
                            return buyBtn.checked ? Theme.buyGreen : Theme.sellRed
                        }
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }
            }
        }

        Frame {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 150; Layout.maximumHeight: 150; padding: 0
            background: Rectangle {
                color: Theme.bgCard; radius: Theme.radiusMd
                border.color: Theme.borderLight; border.width: 1
            }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.spacingMd; spacing: Theme.spacingSm
                Label {
                    text: "Log"; font.bold: true; font.pixelSize: Theme.fontSizeSm; color: Theme.textSecondary
                }
                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    TextArea {
                        id: logArea
                        readOnly: true; placeholderText: "Response log..."
                        color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSm; font.family: Theme.fontMono
                        placeholderTextColor: Theme.textMuted
                        background: Rectangle { color: Theme.bgDeep; radius: Theme.radiusSm }
                    }
                }
            }
        }
    }

    Connections {
        target: ClientWorker
        function onOrderAck(orderId, side, price, qty, uid) {
            logArea.append("[" + new Date().toLocaleTimeString() + "] #" + String(orderId) + " "
                + (side === 1 ? "BUY" : "SELL") + " " + price + "×" + qty + " uid=" + uid + " → OK")
        }
        function onOrderFilled(orderId) {
            logArea.append("[" + new Date().toLocaleTimeString() + "] #" + String(orderId) + " → FILLED")
        }
        function onTradeExecuted(price, qty, buyId, sellId) {
            logArea.append("[" + new Date().toLocaleTimeString() + "] TRADE " + price + "×" + qty
                + " buy#" + String(buyId) + " sell#" + String(sellId))
        }
        function onErrorReceived(code) {
            logArea.append("[" + new Date().toLocaleTimeString() + "] ERROR code=" + code)
        }
    }
}
