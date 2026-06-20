import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Label {
            text: "下单"
            font.bold: true
            font.pixelSize: 20
        }

        RowLayout {
            Label { text: "方向" }
            RadioButton { id: buyBtn; text: "Buy"; checked: true }
            RadioButton { id: sellBtn; text: "Sell" }
        }

        TextField {
            id: priceField
            placeholderText: "价格"
            validator: IntValidator { bottom: 1 }
            Layout.preferredWidth: 250
        }

        TextField {
            id: qtyField
            placeholderText: "数量"
            validator: IntValidator { bottom: 1 }
            Layout.preferredWidth: 250
        }

        TextField {
            id: uidField
            placeholderText: "User ID"
            validator: IntValidator { bottom: 1 }
            Layout.preferredWidth: 250
        }

        RowLayout {
            Button {
                text: "发送"
                enabled: ClientWorker.connected
                onClicked: {
                    ClientWorker.sendNewOrder(
                        buyBtn.checked ? 1 : 2,
                        parseInt(priceField.text),
                        parseInt(qtyField.text),
                        parseInt(uidField.text)
                    )
                }
            }
            Button {
                text: "批量买 ×1000"
                enabled: ClientWorker.connected
            }
            Button {
                text: "批量卖 ×1000"
                enabled: ClientWorker.connected
            }
        }

        Label {
            text: "响应日志"
            font.bold: true
            visible: logArea.length > 0
        }

        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true

            TextArea {
                id: logArea
                readOnly: true
                placeholderText: "响应日志..."
            }
        }
    }

    Connections {
        target: ClientWorker
        function onOrderAck(orderId, side, price, qty, uid) {
            logArea.append("[%1] #%2 %3 %4×%5 uid=%6 → OK"
                .arg(new Date().toLocaleTimeString())
                .arg(String(orderId))
                .arg(side === 1 ? "BUY" : "SELL")
                .arg(price)
                .arg(qty)
                .arg(uid))
        }
        function onOrderFilled(orderId) {
            logArea.append("[%1] #%2 → FILLED".arg(new Date().toLocaleTimeString()).arg(orderId))
        }
        function onTradeExecuted(price, qty, buyId, sellId) {
            logArea.append("[%1] 成交 %2×%3  buy#%4  sell#%5"
                .arg(new Date().toLocaleTimeString())
                .arg(price).arg(qty)
                .arg(String(buyId)).arg(String(sellId)))
        }
        function onErrorReceived(code) {
            logArea.append("[%1] ERROR code=%2".arg(new Date().toLocaleTimeString()).arg(code))
        }
    }
}
