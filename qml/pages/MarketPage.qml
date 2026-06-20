import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    id: root
    background: null

    property int bidPrice: 0
    property int bidVol: 0
    property int askPrice: 0
    property int askVol: 0
    property int maxDepth: 1

    header: Rectangle {
        height: 36
        color: "#0A0A0E"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16; anchors.rightMargin: 16
            Label {
                text: "Order Book"
                font.bold: true; font.pixelSize: Theme.fontSizeMd
                color: Theme.textPrimary
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "Bid " + root.bidPrice + "  vol " + root.bidVol
                font.pixelSize: Theme.fontSizeXs; color: Theme.buyGreen
                font.family: Theme.fontMono; visible: root.bidVol > 0
            }
            Rectangle { width: 1; height: 12; color: Theme.borderLight; Layout.leftMargin: 8; Layout.rightMargin: 8 }
            Label {
                text: "Ask " + root.askPrice + "  vol " + root.askVol
                font.pixelSize: Theme.fontSizeXs; color: Theme.sellRed
                font.family: Theme.fontMono; visible: root.askVol > 0
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        Frame {
            Layout.fillWidth: true; padding: 0
            background: Rectangle {
                color: Theme.bgCard; radius: Theme.radiusMd
                border.color: Theme.borderLight; border.width: 1
            }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.spacingLg; spacing: Theme.spacingSm
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Bid"; color: Theme.buyGreen; font.bold: true; font.pixelSize: Theme.fontSizeMd }
                    Item { Layout.fillWidth: true }
                    Label { text: "Ask"; color: Theme.sellRed; font.bold: true; font.pixelSize: Theme.fontSizeMd }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: root.bidPrice > 0 ? String(root.bidPrice) : "—"
                        color: Theme.buyGreen; font.bold: true; font.pixelSize: Theme.fontSizeXxl; font.family: Theme.fontMono
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: root.askPrice > 0 ? String(root.askPrice) : "—"
                        color: Theme.sellRed; font.bold: true; font.pixelSize: Theme.fontSizeXxl; font.family: Theme.fontMono
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Vol: " + root.bidVol; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeSm; font.family: Theme.fontMono }
                    Item { Layout.fillWidth: true }
                    Label { text: root.askPrice > 0 && root.bidPrice > 0 ? "Spread: " + (root.askPrice - root.bidPrice) : ""; color: Theme.textAccent; font.pixelSize: Theme.fontSizeSm; font.family: Theme.fontMono }
                    Item { Layout.fillWidth: true }
                    Label { text: "Vol: " + root.askVol; color: Theme.textSecondary; font.pixelSize: Theme.fontSizeSm; font.family: Theme.fontMono }
                }
            }
        }

        Frame {
            Layout.fillWidth: true; Layout.preferredHeight: 160; Layout.maximumHeight: 160; padding: 0
            background: Rectangle {
                color: Theme.bgCard; radius: Theme.radiusMd
                border.color: Theme.borderLight; border.width: 1
            }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.spacingMd; spacing: Theme.spacingXs
                Label {
                    text: "Market Depth"
                    font.bold: true; font.pixelSize: Theme.fontSizeSm; color: Theme.textSecondary
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    DepthBar {
                        Layout.fillWidth: true; side: "ask"
                        price: root.askPrice; volume: root.askVol; maxVolume: root.maxDepth
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderLight }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    DepthBar {
                        Layout.fillWidth: true; side: "bid"
                        price: root.bidPrice; volume: root.bidVol; maxVolume: root.maxDepth
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        id: refBtn
                        text: "⟳ Refresh"
                        enabled: ClientWorker.connected
                        onClicked: ClientWorker.sendBookQuery()
                        font.pixelSize: Theme.fontSizeSm
                        contentItem: Label {
                            text: "⟳ Refresh"
                            color: refBtn.enabled ? Theme.buyGreen : Theme.textMuted
                            font.pixelSize: Theme.fontSizeSm; font.bold: true
                        }
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: !refBtn.enabled ? "transparent" : refBtn.down
                                ? Qt.rgba(0.05, 0.80, 0.51, 0.25)
                                : refBtn.hovered
                                ? Qt.rgba(0.05, 0.80, 0.51, 0.15)
                                : Qt.rgba(0.05, 0.80, 0.51, 0.08)
                            border.color: refBtn.enabled ? Qt.rgba(0.05, 0.80, 0.51, 0.4) : Theme.borderLight
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        id: autoBtn
                        checkable: true
                        checked: false
                        font.pixelSize: Theme.fontSizeSm
                        contentItem: Label {
                            text: "Auto"
                            color: autoBtn.checked ? Theme.buyGreen : Theme.textMuted
                            font.pixelSize: Theme.fontSizeSm; font.bold: autoBtn.checked
                        }
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: autoBtn.checked
                                ? (autoBtn.down ? Qt.rgba(0.05,0.80,0.51,0.35) : autoBtn.hovered ? Qt.rgba(0.05,0.80,0.51,0.2) : Qt.rgba(0.05,0.80,0.51,0.1))
                                : (autoBtn.down ? Qt.rgba(0.3,0.3,0.4,0.3) : autoBtn.hovered ? Qt.rgba(0.3,0.3,0.4,0.15) : "transparent")
                            border.color: autoBtn.checked ? Qt.rgba(0.05,0.80,0.51,0.4) : Theme.borderLight
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }
                        Timer {
                            running: autoBtn.checked && ClientWorker.connected
                            interval: 200; repeat: true
                            onTriggered: ClientWorker.sendBookQuery()
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: ClientWorker
        function onBookUpdated(bp, bv, ap, av) {
            root.bidPrice = bp; root.bidVol = bv
            root.askPrice = ap; root.askVol = av
            root.maxDepth = Math.max(bv, av, 1)
        }
    }
}
