import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    id: root
    background: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXl
        spacing: Theme.spacingMd

        Item { Layout.fillHeight: true }

        Label {
            text: "NebulaX-Desk"
            font.bold: true; font.pixelSize: Theme.fontSizeXxl
            color: Theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            text: "Trading Terminal"
            font.pixelSize: Theme.fontSizeMd
            color: Theme.textMuted
            Layout.alignment: Qt.AlignHCenter
        }

        Frame {
            padding: 0
            Layout.preferredWidth: 320
            Layout.alignment: Qt.AlignHCenter
            background: Rectangle {
                color: Theme.bgCard; radius: Theme.radiusLg
                border.color: Theme.borderLight; border.width: 1
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingXl
                spacing: Theme.spacingMd

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingSm
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: ClientWorker.connected ? Theme.buyGreen : Theme.sellRed
                        Behavior on color { ColorAnimation { duration: Theme.animNorm } }
                    }
                    Label {
                        text: ClientWorker.connected ? "Connected" : "Disconnected"
                        color: ClientWorker.connected ? Theme.buyGreen : Theme.sellRed
                        font.bold: true; font.pixelSize: Theme.fontSizeSm
                    }
                }

                Label { text: "Host"; font.pixelSize: Theme.fontSizeXs; color: Theme.textSecondary }
                TextField {
                    id: hostField; text: "192.168.1.13"; placeholderText: "Host"
                    Layout.fillWidth: true
                    font.pixelSize: Theme.fontSizeMd; color: Theme.textPrimary
                    leftPadding: 12; rightPadding: 12; topPadding: 8; bottomPadding: 8
                    placeholderTextColor: Theme.textMuted
                    background: Rectangle {
                        color: Theme.bgDeep; radius: Theme.radiusSm
                        border.color: parent.activeFocus ? Theme.borderFocus : Theme.borderLight
                        border.width: 1
                    }
                }

                Label { text: "Port"; font.pixelSize: Theme.fontSizeXs; color: Theme.textSecondary }
                TextField {
                    id: portField; text: "2250"; placeholderText: "Port"
                    validator: IntValidator { bottom: 1; top: 65535 }
                    Layout.fillWidth: true
                    font.pixelSize: Theme.fontSizeMd; color: Theme.textPrimary
                    leftPadding: 12; rightPadding: 12; topPadding: 8; bottomPadding: 8
                    placeholderTextColor: Theme.textMuted
                    background: Rectangle {
                        color: Theme.bgDeep; radius: Theme.radiusSm
                        border.color: parent.activeFocus ? Theme.borderFocus : Theme.borderLight
                        border.width: 1
                    }
                }

                Button {
                    id: connBtn
                    text: ClientWorker.connected ? "Disconnect" : "Connect"
                    Layout.fillWidth: true; Layout.topMargin: Theme.spacingSm
                    font.bold: true; font.pixelSize: Theme.fontSizeMd
                    onClicked: {
                        if (ClientWorker.connected) ClientWorker.disconnect()
                        else ClientWorker.connectToHost(hostField.text, parseInt(portField.text))
                    }
                    contentItem: Label {
                        text: ClientWorker.connected ? "Disconnect" : "Connect"
                        color: "#FFFFFF"; font.bold: true; font.pixelSize: Theme.fontSizeMd
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: ClientWorker.connected
                            ? (connBtn.down ? Qt.rgba(0.96,0.27,0.36,0.8) : connBtn.hovered ? Qt.rgba(0.96,0.27,0.36,0.9) : Theme.sellRed)
                            : (connBtn.down ? Qt.rgba(0.94,0.72,0.04,0.8) : connBtn.hovered ? Qt.rgba(0.94,0.72,0.04,0.9) : Theme.accent)
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.preferredWidth: 320
            Layout.preferredHeight: 120
            Layout.minimumHeight: 120
            Layout.maximumHeight: 120
            Layout.alignment: Qt.AlignHCenter
            color: Theme.bgCard; radius: Theme.radiusMd
            border.color: Theme.borderLight; border.width: 1
            clip: true

            ScrollView {
                anchors.fill: parent; clip: true; background: null
                TextArea {
                    id: logArea
                    readOnly: true
                    placeholderText: "Connection log..."
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSm; font.family: Theme.fontMono
                    placeholderTextColor: Theme.textMuted
                    background: null
                }
            }
        }
    }

    Connections {
        target: ClientWorker
        function onConnectedChanged() {
            if (ClientWorker.connected)
                logArea.append("[" + new Date().toLocaleTimeString() + "] Connected to " + hostField.text + ":" + portField.text)
            else
                logArea.append("[" + new Date().toLocaleTimeString() + "] Disconnected")
        }
    }
}
