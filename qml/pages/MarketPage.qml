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
                font.bold: true
                font.pixelSize: Theme.fontSizeMd
                color: Theme.textPrimary
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "Bid " + root.bidPrice + "  vol " + root.bidVol
                font.pixelSize: Theme.fontSizeXs
                color: Theme.buyGreen
                font.family: Theme.fontMono
                visible: root.bidVol > 0
            }
            Rectangle { width: 1; height: 12; color: Theme.borderLight; Layout.leftMargin: 8; Layout.rightMargin: 8 }
            Label {
                text: "Ask " + root.askPrice + "  vol " + root.askVol
                font.pixelSize: Theme.fontSizeXs
                color: Theme.sellRed
                font.family: Theme.fontMono
                visible: root.askVol > 0
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        // Price spread
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
                spacing: Theme.spacingSm

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Bid"
                        color: Theme.buyGreen; font.bold: true
                        font.pixelSize: Theme.fontSizeMd
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "Ask"
                        color: Theme.sellRed; font.bold: true
                        font.pixelSize: Theme.fontSizeMd
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: root.bidPrice > 0 ? String(root.bidPrice) : "—"
                        color: Theme.buyGreen; font.bold: true
                        font.pixelSize: Theme.fontSizeXxl
                        font.family: Theme.fontMono
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: root.askPrice > 0 ? String(root.askPrice) : "—"
                        color: Theme.sellRed; font.bold: true
                        font.pixelSize: Theme.fontSizeXxl
                        font.family: Theme.fontMono
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Vol: " + root.bidVol
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSm
                        font.family: Theme.fontMono
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: root.askPrice > 0 && root.bidPrice > 0 ? "Spread: " + (root.askPrice - root.bidPrice) : ""
                        color: Theme.textAccent
                        font.pixelSize: Theme.fontSizeSm
                        font.family: Theme.fontMono
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "Vol: " + root.askVol
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSm
                        font.family: Theme.fontMono
                    }
                }
            }
        }

        // Depth visualization
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
                spacing: Theme.spacingXs

                Label {
                    text: "Market Depth"
                    font.bold: true; font.pixelSize: Theme.fontSizeSm
                    color: Theme.textSecondary
                }

                // Ask side (reversed, best ask at top)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    DepthBar {
                        Layout.fillWidth: true
                        side: "ask"
                        price: root.askPrice
                        volume: root.askVol
                        maxVolume: root.maxDepth
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1; color: Theme.borderLight
                }

                // Bid side
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    DepthBar {
                        Layout.fillWidth: true
                        side: "bid"
                        price: root.bidPrice
                        volume: root.bidVol
                        maxVolume: root.maxDepth
                    }
                }

                Item { Layout.fillWidth: true }

                // Control buttons
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "⟳ Refresh"
                        enabled: ClientWorker.connected
                        onClicked: ClientWorker.sendBookQuery()
                        font.pixelSize: Theme.fontSizeSm
                    }
                    Item { Layout.fillWidth: true }
                    CheckBox {
                        id: autoRef
                        text: "Auto 2s"
                        font.pixelSize: Theme.fontSizeSm
                        contentItem: Label {
                            text: "Auto 2s"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSm
                            verticalAlignment: Text.AlignVCenter
                        }
                        indicator: Rectangle {
                            width: 14; height: 14; radius: 3
                            color: autoRef.checked ? Theme.accent : Theme.bgDeep
                            border.color: Theme.borderLight; border.width: 1
                            Rectangle {
                                anchors.centerIn: parent
                                width: 6; height: 6; radius: 2
                                color: autoRef.checked ? "#0A0A0E" : "transparent"
                            }
                        }
                        Timer {
                            running: autoRef.checked && ClientWorker.connected
                            interval: 2000; repeat: true
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
