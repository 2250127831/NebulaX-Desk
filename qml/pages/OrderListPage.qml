import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    id: listPage
    background: null

    Component.onCompleted: { ClientWorker.loadPersistedOrders() }

    property var orderIndex: ({})
    property var cardRefs: ({})
    property var pendingFills: ({})
    property bool multiSelectMode: false
    property var selectedIds: []
    property string filterStatus: "ALL"

    onMultiSelectModeChanged: {
        if (!multiSelectMode) {
            selectedIds = []
            for (var i = 0; i < orderModel.count; i++) {
                var card = cardRefs[orderModel.get(i).orderId]
                if (card) card.checked = false
            }
        }
    }

    onFilterStatusChanged: {
        multiSelectMode = false
        selectedIds = []
        for (var i = 0; i < orderModel.count; i++) {
            var card = cardRefs[orderModel.get(i).orderId]
            if (card) card.checked = false
        }
    }

    header: ColumnLayout {
        spacing: 0

        Rectangle {
            Layout.fillWidth: true; height: 36; color: "#0A0A0E"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 16; spacing: 4

                Button {
                    id: selBtn
                    text: listPage.multiSelectMode ? "☑ Done" : "☐ Select"
                    flat: true; font.pixelSize: Theme.fontSizeSm
                    onClicked: {
                        if (listPage.multiSelectMode) { listPage.multiSelectMode = false }
                        else {
                            listPage.multiSelectMode = true
                            var ids = []
                            for (var i = 0; i < orderModel.count; i++) {
                                var d = orderModel.get(i); var s = d.status; var f = listPage.filterStatus
                                if (f === "ALL" || (f === "OPEN" && s === "OPEN") || (f === "PARTIAL" && s === "PARTIALLY_FILLED") || f === s) {
                                    ids.push(d.orderId); var card = listPage.cardRefs[d.orderId]
                                    if (card) card.checked = true
                                }
                            }
                            listPage.selectedIds = ids
                        }
                    }
                    contentItem: Label {
                        text: listPage.multiSelectMode ? "☑ Done" : "☐ Select"
                        color: Theme.textSecondary; font.pixelSize: Theme.fontSizeSm
                    }
                    background: Rectangle {
                        color: selBtn.down ? Qt.rgba(1,1,1,0.1) : selBtn.hovered ? Qt.rgba(1,1,1,0.05) : "transparent"
                        border.color: Theme.borderLight; border.width: 1; radius: Theme.radiusSm
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }

                Button {
                    id: cancelBtn
                    text: "Cancel (" + listPage.selectedIds.length + ")"
                    enabled: listPage.selectedIds.length > 0
                    visible: listPage.multiSelectMode && listPage.filterStatus !== "FILLED" && listPage.filterStatus !== "CANCELLED"
                    flat: true; font.pixelSize: Theme.fontSizeSm
                    onClicked: {
                        for (var i = 0; i < listPage.selectedIds.length; i++) {
                            var oid = listPage.selectedIds[i]; var idx = listPage.orderIndex[oid]
                            ClientWorker.sendCancel(oid, idx !== undefined ? orderModel.get(idx).uid : 0)
                        }
                        listPage.multiSelectMode = false
                    }
                    contentItem: Label {
                        text: "Cancel (" + listPage.selectedIds.length + ")"
                        color: cancelBtn.enabled ? Theme.sellRed : Theme.textMuted; font.pixelSize: Theme.fontSizeSm
                    }
                    background: Rectangle {
                        color: cancelBtn.enabled ? (cancelBtn.down ? Qt.rgba(0.96,0.27,0.36,0.25) : cancelBtn.hovered ? Qt.rgba(0.96,0.27,0.36,0.12) : "transparent") : "transparent"
                        border.color: cancelBtn.enabled ? Qt.rgba(0.96,0.27,0.36,0.3) : Theme.borderLight; border.width: 1; radius: Theme.radiusSm
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }

                Item { Layout.fillWidth: true }
                Label {
                    text: orderModel.count + " orders"
                    font.pixelSize: Theme.fontSizeXs; color: Theme.textMuted
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 28; color: "#0A0A0E"
            Row {
                anchors.left: parent.left; anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter; spacing: 2

                Repeater {
                    model: ["ALL", "OPEN", "PARTIAL", "FILLED", "CANCELLED"]
                    delegate: Rectangle {
                        id: tabItem; height: 22
                        width: label.width + 20; radius: 11
                        color: listPage.filterStatus === modelData
                            ? Qt.rgba(0.94, 0.72, 0.04, 0.15) : (tabMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                        Behavior on color { ColorAnimation { duration: 80 } }

                        Label {
                            id: label; anchors.centerIn: parent; text: modelData
                            font.pixelSize: Theme.fontSizeXs
                            font.bold: listPage.filterStatus === modelData
                            color: listPage.filterStatus === modelData ? Theme.accent : (tabMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                        }

                        MouseArea {
                            id: tabMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: listPage.filterStatus = modelData
                        }
                    }
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 8
                    text: {
                        var total = orderModel.count; var open = 0, partial = 0, filled = 0, cancelled = 0
                        for (var i = 0; i < total; i++) {
                            var s = orderModel.get(i).status
                            if (s === "OPEN") open++
                            else if (s === "PARTIALLY_FILLED") partial++
                            else if (s === "FILLED") filled++
                            else if (s === "CANCELLED") cancelled++
                        }
                        return "  " + open + " / " + partial + " / " + filled + " / " + cancelled
                    }
                    font.pixelSize: Theme.fontSizeXs; color: Theme.textMuted
                }
            }
        }
    }

    ListModel { id: orderModel }

    ListView {
        id: listView; anchors.fill: parent; anchors.margins: Theme.spacingSm
        model: orderModel; spacing: Theme.spacingXs; clip: true

        delegate: Item {
            width: listView.width - 4; height: visible ? 52 : 0
            required property int index
            visible: { var s = orderModel.get(index).status; var f = listPage.filterStatus; return f === "ALL" || (f === "OPEN" && s === "OPEN") || (f === "PARTIAL" && s === "PARTIALLY_FILLED") || f === s }

            OrderCard {
                id: cardItem; width: parent.width; height: parent.height
                orderId: orderModel.get(parent.index).orderId
                side: orderModel.get(parent.index).side
                price: orderModel.get(parent.index).price
                qty: orderModel.get(parent.index).qty
                filledQty: orderModel.get(parent.index).filledQty
                status: orderModel.get(parent.index).status
                timeStr: orderModel.get(parent.index).timeStr
                multiSelectMode: listPage.multiSelectMode

                onCancelRequested: function(id) {
                    var d = orderModel.get(parent.index)
                    ClientWorker.sendCancel(id, d ? d.uid : 0)
                }
                onLongPressed: { listPage.multiSelectMode = true }
                onCheckedChanged: {
                    var id = orderModel.get(parent.index).orderId
                    if (checked) { if (listPage.selectedIds.indexOf(id) < 0) listPage.selectedIds = listPage.selectedIds.concat([id]) }
                    else { listPage.selectedIds = listPage.selectedIds.filter(function(x) { return x !== id }) }
                }
                Component.onCompleted: { listPage.cardRefs[orderModel.get(parent.index).orderId] = cardItem }
            }
        }

        Label {
            anchors.centerIn: parent; text: "No orders"
            color: Theme.textMuted; font.pixelSize: Theme.fontSizeMd
            visible: orderModel.count === 0
        }
    }

    Connections {
        target: ClientWorker
        function onOrderAck(orderId, side, price, qty, uid) {
            var timeStr = new Date().toLocaleTimeString()
            orderModel.append({ orderId: orderId, side: side === 1 ? "BUY" : "SELL", price: price, qty: qty, uid: uid, filledQty: 0, status: "OPEN", timeStr: timeStr })
            orderIndex[orderId] = orderModel.count - 1
            ClientWorker.persistOrder(orderId, side, price, qty, uid, "OPEN", timeStr)
            var pk = pendingFills[orderId]
            if (pk) { addFill(orderId, pk); delete pendingFills[orderId] }
            var idx = orderModel.count - 1
            Qt.callLater(function() { listView.positionViewAtIndex(idx, ListView.Contain) })
        }
        function onOrderLoaded(orderId, side, price, qty, uid, status, timeStr) {
            orderModel.append({ orderId: orderId, side: side === 1 ? "BUY" : "SELL", price: price, qty: qty, uid: uid, filledQty: 0, status: status, timeStr: timeStr })
            orderIndex[orderId] = orderModel.count - 1
        }
        function onOrderFilled(orderId) { setFilled(orderId); ClientWorker.updateOrderStatus(orderId, "FILLED") }
        function onCancelAck(orderId) { updateStatus(orderId, "CANCELLED"); ClientWorker.updateOrderStatus(orderId, "CANCELLED") }
        function onTradeExecuted(price, qty, buyId, sellId) {
            if (addFill(buyId, qty)) ClientWorker.updateOrderStatus(buyId, orderModel.get(orderIndex[buyId]).status)
            else bufferFill(buyId, qty)
            if (addFill(sellId, qty)) ClientWorker.updateOrderStatus(sellId, orderModel.get(orderIndex[sellId]).status)
            else bufferFill(sellId, qty)
        }
        function onConnectedChanged() { }
    }

    function bufferFill(orderId, tradeQty) { if (!pendingFills[orderId]) pendingFills[orderId] = 0; pendingFills[orderId] += tradeQty }
    function addFill(orderId, tradeQty) {
        var idx = orderIndex[orderId]; if (idx === undefined) return false
        var filled = orderModel.get(idx).filledQty + tradeQty; var total = orderModel.get(idx).qty
        var newStatus = filled >= total ? "FILLED" : "PARTIALLY_FILLED"
        orderModel.setProperty(idx, "filledQty", filled); orderModel.setProperty(idx, "status", newStatus)
        var card = cardRefs[orderId]; if (card) { card.filledQty = filled; card.status = newStatus }
        return true
    }
    function setFilled(orderId) {
        var idx = orderIndex[orderId]; if (idx === undefined) return
        orderModel.setProperty(idx, "filledQty", orderModel.get(idx).qty); orderModel.setProperty(idx, "status", "FILLED")
        var card = cardRefs[orderId]; if (card) { card.filledQty = orderModel.get(idx).qty; card.status = "FILLED" }
    }
    function updateStatus(orderId, newStatus) {
        var idx = orderIndex[orderId]; if (idx === undefined) return
        orderModel.setProperty(idx, "status", newStatus)
        var card = cardRefs[orderId]; if (card) card.status = newStatus
    }
}
