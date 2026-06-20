import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    id: root
    background: null

    property var orderIndex: ({})
    property var cardRefs: ({})
    property var pendingFills: ({})
    property bool multiSelectMode: false
    property var selectedIds: []

    header: Rectangle {
        height: 36
        color: "#0A0A0E"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8; anchors.rightMargin: 16
            spacing: 4

            Button {
                text: root.multiSelectMode ? "☑ Done" : "☐ Select"
                flat: true
                font.pixelSize: Theme.fontSizeSm
                onClicked: root.multiSelectMode = !root.multiSelectMode
                contentItem: Label {
                    text: root.multiSelectMode ? "☑ Done" : "☐ Select"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSm
                }
                background: Rectangle {
                    color: "transparent"
                    border.color: Theme.borderLight
                    border.width: 1; radius: Theme.radiusSm
                }
            }
            Button {
                text: "Cancel (" + root.selectedIds.length + ")"
                enabled: root.selectedIds.length > 0
                visible: root.multiSelectMode
                flat: true
                font.pixelSize: Theme.fontSizeSm
                onClicked: {
                    for (var i = 0; i < root.selectedIds.length; i++)
                        ClientWorker.sendCancel(root.selectedIds[i], 0)
                    root.multiSelectMode = false
                }
                contentItem: Label {
                    text: "Cancel (" + root.selectedIds.length + ")"
                    color: Theme.sellRed
                    font.pixelSize: Theme.fontSizeSm
                }
                background: Rectangle {
                    color: "transparent"
                    border.color: Theme.sellRed
                    border.width: 1; radius: Theme.radiusSm
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                text: orderModel.count + " orders"
                font.pixelSize: Theme.fontSizeXs
                color: Theme.textMuted
            }
        }
    }

    ListModel { id: orderModel }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: Theme.spacingSm
        model: orderModel
        spacing: Theme.spacingXs
        clip: true

        delegate: Item {
            width: listView.width - 4
            height: 52
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

                onCancelRequested: function(id) {
                    var d = orderModel.get(parent.index)
                    ClientWorker.sendCancel(id, d ? d.uid : 0)
                }
                onLongPressed: { root.multiSelectMode = true }

                Component.onCompleted: {
                    root.cardRefs[orderModel.get(parent.index).orderId] = cardItem
                }
            }
        }

        Label {
            anchors.centerIn: parent
            text: "No orders"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSizeMd
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
            var pk = pendingFills[orderId]
            if (pk) {
                addFill(orderId, pk)
                delete pendingFills[orderId]
            }
            // Animate new item into view
            var idx = orderModel.count - 1
            Qt.callLater(function() {
                listView.positionViewAtIndex(idx, ListView.Contain)
            })
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
