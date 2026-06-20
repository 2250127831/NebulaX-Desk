import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

ApplicationWindow {
    id: window
    title: "NebulaX-Desk"
    width: 900
    height: 600
    visible: true

    header: RowLayout {
        TabBar {
            id: nav
            Layout.fillWidth: true

            TabButton { text: "连接" }
            TabButton { text: "下单" }
            TabButton { text: "行情" }
            TabButton { text: "订单列表" }
        }

        Rectangle {
            width: 12; height: 12; radius: 6
            color: ClientWorker.connected ? "#4CAF50" : "#F44336"
            Behavior on color { ColorAnimation { duration: 300 } }
            Layout.rightMargin: 12
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: nav.currentIndex

        ConnectionPage {}
        OrderPage {}
        MarketPage {}
        OrderListPage {}
    }
}
