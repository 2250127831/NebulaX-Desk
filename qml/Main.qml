import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

ApplicationWindow {
    id: window
    title: "NebulaX-Desk"
    width: 960
    height: 640
    visible: true
    color: Theme.bgDeep
    minimumWidth: 640
    minimumHeight: 480

    // ── Breathing ambient glow ──
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        radius: width
        color: Qt.rgba(0.94, 0.72, 0.04, breathGlow * 0.015)
    }

    property real breathGlow: 0.3
    SequentialAnimation on breathGlow {
        loops: Animation.Infinite
        NumberAnimation { from: 0.3; to: 1.0; duration: 4000; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.0; to: 0.3; duration: 4000; easing.type: Easing.InOutSine }
    }

    // ── Header / Navigation ──
    header: Rectangle {
        height: 44
        color: "#0A0A0E"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8; anchors.rightMargin: 16
            spacing: 0

            TabBar {
                id: nav
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: null
                spacing: 0

                TabButton {
                    text: "⚙  连接"
                    font.pixelSize: Theme.fontSizeSm
                }
                TabButton {
                    text: "⤒  下单"
                    font.pixelSize: Theme.fontSizeSm
                }
                TabButton {
                    text: "☰  行情"
                    font.pixelSize: Theme.fontSizeSm
                }
                TabButton {
                    text: "☷  订单"
                    font.pixelSize: Theme.fontSizeSm
                }
            }

            // Connection indicator with breathing ring
            Item {
                width: 36; height: parent.height
                Rectangle {
                    anchors.centerIn: parent
                    width: 8; height: 8; radius: 4
                    color: ClientWorker.connected ? Theme.buyGreen : Theme.sellRed
                    Behavior on color { ColorAnimation { duration: Theme.animNorm } }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 18; height: 18; radius: 9
                    color: "transparent"
                    border.width: 1
                    border.color: ClientWorker.connected ? Theme.buyGreen : Theme.sellRed
                    opacity: window.breathGlow * 0.4
                    Behavior on border.color { ColorAnimation { duration: Theme.animNorm } }
                }
            }
        }
    }

    // ── Pages ──
    StackLayout {
        id: pages
        anchors.fill: parent
        currentIndex: nav.currentIndex

        // Fade transition
        onCurrentIndexChanged: {
            fadeAnim.restart()
        }
        PropertyAnimation {
            id: fadeAnim
            target: pages.currentItem || pages.itemAt(nav.currentIndex)
            property: "opacity"
            from: 0.6; to: 1.0
            duration: Theme.animNorm
            easing.type: Easing.OutCubic
        }

        ConnectionPage {}
        OrderPage {}
        MarketPage {}
        OrderListPage {}
    }

    // ── Status bar ──
    footer: Rectangle {
        height: 22
        color: "#08080A"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            Label {
                text: "NebulaX-Desk v1.0"
                font.pixelSize: Theme.fontSizeXs
                color: Theme.textMuted
            }
            Item { Layout.fillWidth: true }
            Label {
                text: ClientWorker.connected ? "● Connected" : "○ Disconnected"
                font.pixelSize: Theme.fontSizeXs
                color: ClientWorker.connected ? Theme.buyGreen : Theme.sellRed
                font.family: Theme.fontMono
            }
        }
    }
}
