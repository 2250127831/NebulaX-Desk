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

    // ── Top bar (drag + branding + window controls) ──
    Rectangle {
        id: topBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 40
        color: "#0C0C12"

        DragHandler {
            id: titleDrag
            acceptedButtons: Qt.LeftButton
            onActiveChanged: if (active) window.startSystemMove()
            target: null
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onDoubleClicked: {
                window.visibility === Window.Maximized
                    ? window.showNormal() : window.showMaximized()
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 8
            spacing: 8

            Label {
                text: "◆"
                color: Theme.accent
                font.pixelSize: Theme.fontSizeMd
            }
            Label {
                text: "NebulaX"
                font.bold: true; font.pixelSize: Theme.fontSizeMd
                color: Theme.textPrimary
            }
            Item { Layout.fillWidth: true }

            // Window controls
            Row {
                spacing: 2
                Button {
                    text: "─"
                    width: 36; height: 28; flat: true; font.pixelSize: 14
                    onClicked: window.showMinimized()
                    contentItem: Label {
                        text: "─"
                        color: parent.hovered ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgHover : "transparent"
                        radius: 4
                    }
                }
                Button {
                    id: maxBtn
                    text: window.visibility === Window.Maximized ? "❐" : "□"
                    width: 36; height: 28; flat: true; font.pixelSize: 12
                    onClicked: window.visibility === Window.Maximized
                        ? window.showNormal() : window.showMaximized()
                    contentItem: Label {
                        text: window.visibility === Window.Maximized ? "❐" : "□"
                        color: parent.hovered ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgHover : "transparent"; radius: 4
                    }
                }
                Button {
                    id: closeBtn
                    text: "✕"
                    width: 40; height: 28; flat: true; font.pixelSize: 12
                    onClicked: window.close()
                    contentItem: Label {
                        text: "✕"
                        color: parent.hovered ? "#FFFFFF" : Theme.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? Theme.sellRed : "transparent"; radius: 4
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }
            }
        }
    }

    // ── Left sidebar ──
    Rectangle {
        id: sidebar
        anchors.left: parent.left; anchors.top: topBar.bottom; anchors.bottom: statusBar.top
        width: 64
        color: "#0C0C12"

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 8; anchors.bottomMargin: 8
            spacing: 2

            Repeater {
                model: [
                    { icon: "⚙",  label: "连接", page: 0 },
                    { icon: "⤒",  label: "下单", page: 1 },
                    { icon: "☰",  label: "行情", page: 2 },
                    { icon: "☷",  label: "订单", page: 3 },
                ]
                delegate: Item {
                    Layout.fillWidth: true
                    height: 56
                    property bool active: navIndex === modelData.page

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 4; anchors.rightMargin: 4
                        radius: 8
                        color: active ? Qt.rgba(0.94, 0.72, 0.04, 0.12)
                                     : (hoverArea.containsMouse ? Theme.bgHover : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    // Active indicator
                    Rectangle {
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        anchors.topMargin: 8; anchors.bottomMargin: 8
                        width: 3; radius: 2
                        color: Theme.accent
                        opacity: active ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.animNorm } }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Label {
                            text: modelData.icon
                            font.pixelSize: 18
                            color: active ? Theme.accent : Theme.textMuted
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            text: modelData.label
                            font.pixelSize: 9
                            color: active ? Theme.accent : Theme.textMuted
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: navIndex = modelData.page
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Connection indicator at bottom
            Item {
                Layout.fillWidth: true
                height: 32
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
        }
    }

    property int navIndex: 0

    // ── Content area ──
    StackLayout {
        id: pages
        anchors.left: sidebar.right; anchors.right: parent.right
        anchors.top: topBar.bottom; anchors.bottom: statusBar.top
        currentIndex: navIndex

        onCurrentIndexChanged: { fadeAnim.restart() }
        PropertyAnimation {
            id: fadeAnim
            target: pages.currentItem || pages.itemAt(navIndex)
            property: "opacity"
            from: 0.6; to: 1.0; duration: Theme.animNorm; easing.type: Easing.OutCubic
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
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
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

    // ── Resize handles ──
    MouseArea { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 4; cursorShape: Qt.SizeVerCursor; onPressed: window.startSystemResize(Qt.TopEdge) }
    MouseArea { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 4; cursorShape: Qt.SizeVerCursor; onPressed: window.startSystemResize(Qt.BottomEdge) }
    MouseArea { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor; onPressed: window.startSystemResize(Qt.LeftEdge) }
    MouseArea { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4; cursorShape: Qt.SizeHorCursor; onPressed: window.startSystemResize(Qt.RightEdge) }
    MouseArea { anchors.left: parent.left; anchors.top: parent.top; width: 8; height: 8; cursorShape: Qt.SizeFDiagCursor; onPressed: window.startSystemResize(Qt.TopLeftEdge) }
    MouseArea { anchors.right: parent.right; anchors.top: parent.top; width: 8; height: 8; cursorShape: Qt.SizeBDiagCursor; onPressed: window.startSystemResize(Qt.TopRightEdge) }
    MouseArea { anchors.left: parent.left; anchors.bottom: parent.bottom; width: 8; height: 8; cursorShape: Qt.SizeBDiagCursor; onPressed: window.startSystemResize(Qt.BottomLeftEdge) }
    MouseArea { anchors.right: parent.right; anchors.bottom: parent.bottom; width: 8; height: 8; cursorShape: Qt.SizeFDiagCursor; onPressed: window.startSystemResize(Qt.BottomRightEdge) }
}
