import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    id: root
    background: null
    padding: 0

    header: Rectangle {
        height: 36
        color: "#0A0A0E"
        Label {
            anchors.left: parent.left; anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Place Order"
            font.bold: true; font.pixelSize: Theme.fontSizeMd
            color: Theme.textPrimary
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        // Order form card
        Frame {
            Layout.fillWidth: true
            padding: 0
            background: Rectangle {
                color: Theme.bgCard; radius: Theme.radiusMd
                border.color: Theme.borderLight; border.width: 1
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingLg
                spacing: Theme.spacingMd

                // Side selection
                RowLayout {
                    spacing: Theme.spacingSm
                    ButtonGroup { id: sideGroup }
                    Button {
                        id: buyBtn; text: "Buy"
                        checkable: true; checked: true
                        ButtonGroup.group: sideGroup
                        font.pixelSize: Theme.fontSizeMd; font.bold: true
                        contentItem: Label {
                            text: "Buy"; color: buyBtn.checked ? "#FFFFFF" : Theme.buyGreen
                            font.bold: true; font.pixelSize: Theme.fontSizeMd
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: buyBtn.checked ? Theme.buyGreen : Theme.bgDeep
                            border.color: buyBtn.checked ? Theme.buyGreen : Theme.borderLight
                            border.width: 1
                        }
                        Layout.preferredWidth: 80
                    }
                    Button {
                        id: sellBtn; text: "Sell"
                        checkable: true
                        ButtonGroup.group: sideGroup
                        font.pixelSize: Theme.fontSizeMd; font.bold: true
                        contentItem: Label {
                            text: "Sell"; color: sellBtn.checked ? "#FFFFFF" : Theme.sellRed
                            font.bold: true; font.pixelSize: Theme.fontSizeMd
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: sellBtn.checked ? Theme.sellRed : Theme.bgDeep
                            border.color: sellBtn.checked ? Theme.sellRed : Theme.borderLight
                            border.width: 1
                        }
                        Layout.preferredWidth: 80
                    }
                }

                // Price field
                Label { text: "Price"; font.pixelSize: Theme.fontSizeXs; color: Theme.textSecondary }
                TextField {
                    id: priceField
                    placeholderText: "0"
                    validator: IntValidator { bottom: 1 }
                    Layout.fillWidth: true
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLg
                    color: Theme.textPrimary
                    leftPadding: 12; rightPadding: 12; topPadding: 8; bottomPadding: 8
                    placeholderTextColor: Theme.textMuted
                    background: Rectangle {
                        color: Theme.bgDeep; radius: Theme.radiusSm
                        border.color: parent.activeFocus ? Theme.borderFocus : Theme.borderLight
                        border.width: 1
                    }
                }

                // Qty field
                Label { text: "Quantity"; font.pixelSize: Theme.fontSizeXs; color: Theme.textSecondary }
                TextField {
                    id: qtyField
                    placeholderText: "0"
                    validator: IntValidator { bottom: 1 }
                    Layout.fillWidth: true
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLg
                    color: Theme.textPrimary
                    leftPadding: 12; rightPadding: 12; topPadding: 8; bottomPadding: 8
                    placeholderTextColor: Theme.textMuted
                    background: Rectangle {
                        color: Theme.bgDeep; radius: Theme.radiusSm
                        border.color: parent.activeFocus ? Theme.borderFocus : Theme.borderLight
                        border.width: 1
                    }
                }

                // UID field
                Label { text: "User ID"; font.pixelSize: Theme.fontSizeXs; color: Theme.textSecondary }
                TextField {
                    id: uidField
                    placeholderText: "0"
                    validator: IntValidator { bottom: 1 }
                    Layout.fillWidth: true
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLg
                    color: Theme.textPrimary
                    leftPadding: 12; rightPadding: 12; topPadding: 8; bottomPadding: 8
                    placeholderTextColor: Theme.textMuted
                    background: Rectangle {
                        color: Theme.bgDeep; radius: Theme.radiusSm
                        border.color: parent.activeFocus ? Theme.borderFocus : Theme.borderLight
                        border.width: 1
                    }
                }

                // Send button
                Button {
                    text: "Send Order"
                    enabled: ClientWorker.connected && priceField.text.length > 0 && qtyField.text.length > 0 && uidField.text.length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingSm
                    font.bold: true; font.pixelSize: Theme.fontSizeMd
                    onClicked: {
                        ClientWorker.sendNewOrder(
                            buyBtn.checked ? 1 : 2,
                            parseInt(priceField.text),
                            parseInt(qtyField.text),
                            parseInt(uidField.text)
                        )
                    }
                    contentItem: Label {
                        text: "Send Order"
                        color: "#FFFFFF"
                        font.bold: true; font.pixelSize: Theme.fontSizeMd
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: buyBtn.checked ? Theme.buyGreen : Theme.sellRed
                        opacity: parent.enabled ? 1 : 0.4
                    }
                }

                // Quick actions
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm
                    Button {
                        text: "Buy ×1000"
                        enabled: ClientWorker.connected
                        Layout.fillWidth: true
                        font.pixelSize: Theme.fontSizeSm
                        onClicked: {
                            ClientWorker.sendNewOrder(1, parseInt(priceField.text) || 1,
                                (parseInt(qtyField.text) || 1) * 1000, parseInt(uidField.text))
                        }
                    }
                    Button {
                        text: "Sell ×1000"
                        enabled: ClientWorker.connected
                        Layout.fillWidth: true
                        font.pixelSize: Theme.fontSizeSm
                        onClicked: {
                            ClientWorker.sendNewOrder(2, parseInt(priceField.text) || 1,
                                (parseInt(qtyField.text) || 1) * 1000, parseInt(uidField.text))
                        }
                    }
                }
            }
        }

        // Response log
        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0
            background: Rectangle {
                color: Theme.bgCard; radius: Theme.radiusMd
                border.color: Theme.borderLight; border.width: 1
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMd
                spacing: Theme.spacingSm

                Label {
                    text: "Log"
                    font.bold: true; font.pixelSize: Theme.fontSizeSm
                    color: Theme.textSecondary
                }

                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true
                    TextArea {
                        id: logArea
                        readOnly: true
                        placeholderText: "Response log..."
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeSm
                        font.family: Theme.fontMono
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
