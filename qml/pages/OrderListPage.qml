import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    id: root

    property bool multiSelectMode: false
    property var selectedIds: []
    property var orderIndex: ({})
    property var cardRefs: ({})
    property var pendingFills: ({})

    header: RowLayout {
        Button {
            text: root.multiSelectMode ? "☑ 完成" : "☐ 多选"
            onClicked: root.multiSelectMode = !root.multiSelectMode
        }
        Button {
            text: "批量撤单 (" + root.selectedIds.length + ")"
            enabled: root.selectedIds.length > 0
            visible: root.multiSelectMode
            onClicked: {
                for (var i = 0; i < root.selectedIds.length; i++)
                    ClientWorker.sendCancel(root.selectedIds[i], 0)
                root.multiSelectMode = false
            }
        }
        Item { Layout.fillWidth: true }
        Label { text: "共 " + orderModel.count + " 笔"; font.pixelSize: 12; color: "#666" }
    }

    ListModel { id: orderModel }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 8
        model: orderModel
        spacing: 6
        clip: true

        delegate: Item {
            width: listView.width - 16
            height: 56
            required property int index

            OrderCard {
                id: cardItem
                width: parent.width
                height: parent.height
                orderId: orderModel.get(parent.index).orderId
                side: orderModel.get(parent.index).side
                price: orderModel.get(parent.index).price
                qty: orderModel.get(parent.index).qty
                filledQty: orderModel.get(parent.index).filledQty
                status: orderModel.get(parent.index).status
                timeStr: orderModel.get(parent.index).timeStr

                multiSelectMode: root.multiSelectMode
                checkable: {
                    var s = orderModel.get(parent.index).status
                    return s === "OPEN" || s === "PARTIALLY_FILLED"
                }

                onCancelRequested: function(id) {
                    var d = orderModel.get(parent.index)
                    ClientWorker.sendCancel(id, d ? d.uid : 0)
                }
                onLongPressed: {
                    root.multiSelectMode = true
                }

                Component.onCompleted: {
                    root.cardRefs[orderModel.get(parent.index).orderId] = cardItem
                }
            }
        }

        Label {
            anchors.centerIn: parent
            text: "暂无订单"
            color: "#999"
            visible: orderModel.count === 0
        }
    }

    Connections {
        target: ClientWorker
        function onOrderAck(orderId, side, price, qty, uid) {
            orderModel.append({
                orderId: orderId,
                side: side === 1 ? "BUY" : "SELL",
                price: price,
                qty: qty,
                uid: uid,
                filledQty: 0,
                status: "OPEN",
                timeStr: new Date().toLocaleTimeString()
            })
            orderIndex[orderId] = orderModel.count - 1
            // Apply fills that arrived before the ack
            var pk = pendingFills[orderId]
            if (pk) {
                addFill(orderId, pk)
                delete pendingFills[orderId]
            }
        }
        function onOrderFilled(orderId) { setFilled(orderId) }
        function onCancelAck(orderId) { updateStatus(orderId, "CANCELLED") }
        function onTradeExecuted(price, qty, buyId, sellId) {
            if (!addFill(buyId, qty)) bufferFill(buyId, qty)
            if (!addFill(sellId, qty)) bufferFill(sellId, qty)
        }
        function onConnectedChanged() {
            if (!ClientWorker.connected) {
                orderModel.clear()
                orderIndex = ({})
                cardRefs = ({})
                pendingFills = ({})
            }
        }
    }

    function bufferFill(orderId, tradeQty) {
        if (!pendingFills[orderId]) pendingFills[orderId] = 0
        pendingFills[orderId] += tradeQty
    }

    function addFill(orderId, tradeQty) {
        var idx = orderIndex[orderId]
        if (idx === undefined) return false
        var filled = orderModel.get(idx).filledQty + tradeQty
        var total = orderModel.get(idx).qty
        var newStatus = filled >= total ? "FILLED" : "PARTIALLY_FILLED"
        orderModel.setProperty(idx, "filledQty", filled)
        orderModel.setProperty(idx, "status", newStatus)
        var card = cardRefs[orderId]
        if (card) { card.filledQty = filled; card.status = newStatus }
        return true
    }

    function setFilled(orderId) {
        var idx = orderIndex[orderId]
        if (idx === undefined) return
        orderModel.setProperty(idx, "filledQty", orderModel.get(idx).qty)
        orderModel.setProperty(idx, "status", "FILLED")
        var card = cardRefs[orderId]
        if (card) { card.filledQty = orderModel.get(idx).qty; card.status = "FILLED" }
    }

    function updateStatus(orderId, newStatus) {
        var idx = orderIndex[orderId]
        if (idx === undefined) return
        orderModel.setProperty(idx, "status", newStatus)
        var card = cardRefs[orderId]
        if (card) card.status = newStatus
    }
}
