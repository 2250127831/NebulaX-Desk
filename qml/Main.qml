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
    flags: Qt.Window | Qt.FramelessWindowHint

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

    // ── Custom title bar ──
    Rectangle {
        id: titleBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 44
        color: "#0A0A0E"

        // Drag area
        MouseArea {
            anchors.fill: parent
            onPressed: { dragStartX = mouseX; dragStartY = mouseY }
            onPositionChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    window.x += mouseX - dragStartX
                    window.y += mouseY - dragStartY
                }
            }
            onDoubleClicked: {
                window.visibility === Window.Maximized
                    ? window.showNormal()
                    : window.showMaximized()
            }

            property real dragStartX: 0
            property real dragStartY: 0
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 8
            spacing: 8

            // App branding
            Label {
                text: "◆"
                color: Theme.accent
                font.pixelSize: Theme.fontSizeMd
            }
            Label {
                text: "NebulaX"
                font.bold: true
                font.pixelSize: Theme.fontSizeMd
                color: Theme.textPrimary
            }

            // Tab navigation
            TabBar {
                id: nav
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 16
                background: null
                spacing: 0

                TabButton {
                    text: "连接"
                    font.pixelSize: Theme.fontSizeSm
                }
                TabButton {
                    text: "下单"
                    font.pixelSize: Theme.fontSizeSm
                }
                TabButton {
                    text: "行情"
                    font.pixelSize: Theme.fontSizeSm
                }
                TabButton {
                    text: "订单"
                    font.pixelSize: Theme.fontSizeSm
                }
            }

            // Connection indicator
            Item {
                width: 24; height: parent.height
                Rectangle {
                    anchors.centerIn: parent
                    width: 8; height: 8; radius: 4
                    color: ClientWorker.connected ? Theme.buyGreen : Theme.sellRed
                    Behavior on color { ColorAnimation { duration: Theme.animNorm } }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 18; height: 18; radius: 9
                        color: "transparent"
                        border.width: 1
                        border.color: parent.color
                        opacity: window.breathGlow * 0.4
                    }
                }
            }

            // Window controls
            Row {
                spacing: 2
                Layout.rightMargin: -4
                Button {
                    id: minBtn
                    text: "─"
                    width: 36; height: 30
                    flat: true
                    font.pixelSize: 14
                    onClicked: window.showMinimized()
                    contentItem: Label {
                        text: "─"
                        color: minBtn.hovered ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: minBtn.hovered ? Theme.bgHover : "transparent"
                        radius: 4
                    }
                }
                Button {
                    id: maxBtn
                    text: window.visibility === Window.Maximized ? "❐" : "□"
                    width: 36; height: 30
                    flat: true
                    font.pixelSize: 12
                    onClicked: {
                        window.visibility === Window.Maximized
                            ? window.showNormal()
                            : window.showMaximized()
                    }
                    contentItem: Label {
                        text: window.visibility === Window.Maximized ? "❐" : "□"
                        color: maxBtn.hovered ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: maxBtn.hovered ? Theme.bgHover : "transparent"
                        radius: 4
                    }
                }
                Button {
                    id: closeBtn
                    text: "✕"
                    width: 40; height: 30
                    flat: true
                    font.pixelSize: 12
                    onClicked: window.close()
                    contentItem: Label {
                        text: "✕"
                        color: closeBtn.hovered ? "#FFFFFF" : Theme.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: closeBtn.hovered ? Theme.sellRed : "transparent"
                        radius: 4
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }
            }
        }
    }

    // ── Pages ──
    StackLayout {
        id: pages
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: titleBar.bottom
        anchors.bottom: statusBar.top
        currentIndex: nav.currentIndex

        onCurrentIndexChanged: { fadeAnim.restart() }
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
    Rectangle {
        id: statusBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 22
        color: "#08080A"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            Label {
                text: "NebulaX-Desk v1.0"
                font.pixelSize: Theme.fontSizeXs; color: Theme.textMuted
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

    // ── Resize handles (cursorShape on MouseArea only for Qt 6.2 compat) ──
    MouseArea {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 4
        cursorShape: Qt.SizeVerCursor
        onPressed: window.startSystemResize(Qt.TopEdge)
    }
    MouseArea {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 4
        cursorShape: Qt.SizeVerCursor
        onPressed: window.startSystemResize(Qt.BottomEdge)
    }
    MouseArea {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 4
        cursorShape: Qt.SizeHorCursor
        onPressed: window.startSystemResize(Qt.LeftEdge)
    }
    MouseArea {
        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 4
        cursorShape: Qt.SizeHorCursor
        onPressed: window.startSystemResize(Qt.RightEdge)
    }
    MouseArea {
        anchors.left: parent.left; anchors.top: parent.top
        width: 8; height: 8
        cursorShape: Qt.SizeFDiagCursor
        onPressed: window.startSystemResize(Qt.TopLeftEdge)
    }
    MouseArea {
        anchors.right: parent.right; anchors.top: parent.top
        width: 8; height: 8
        cursorShape: Qt.SizeBDiagCursor
        onPressed: window.startSystemResize(Qt.TopRightEdge)
    }
    MouseArea {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        width: 8; height: 8
        cursorShape: Qt.SizeBDiagCursor
        onPressed: window.startSystemResize(Qt.BottomLeftEdge)
    }
    MouseArea {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        width: 8; height: 8
        cursorShape: Qt.SizeFDiagCursor
        onPressed: window.startSystemResize(Qt.BottomRightEdge)
    }
}
