import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    id: root
    property int bidPrice: 0
    property int bidVol: 0
    property int askPrice: 0
    property int askVol: 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Label {
            text: "行情"
            font.bold: true
            font.pixelSize: 20
        }

        Frame {
            ColumnLayout {
                spacing: 8
                Label { text: "卖一  " + root.askPrice + "    " + root.askVol; color: "#4CAF50" }
                Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }
                Label { text: "买一  " + root.bidPrice + "    " + root.bidVol; color: "#F44336" }
            }
        }

        Label {
            text: "价差  " + (askPrice - bidPrice)
            visible: askPrice > 0 && bidPrice > 0
        }

        RowLayout {
            Button {
                text: "刷新"
                enabled: ClientWorker.connected
                onClicked: ClientWorker.sendBookQuery()
            }
            CheckBox {
                id: autoRefresh
                text: "自动刷新"
                Timer {
                    running: autoRefresh.checked && ClientWorker.connected
                    interval: 2000
                    repeat: true
                    onTriggered: ClientWorker.sendBookQuery()
                }
            }
        }
    }

    Connections {
        target: ClientWorker
        function onBookUpdated(bp, bv, ap, av) {
            bidPrice = bp; bidVol = bv
            askPrice = ap; askVol = av
        }
    }
}
