import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NebulaX.Desk

Page {
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Label {
            text: "连接设置"
            font.bold: true
            font.pixelSize: 20
        }

        TextField {
            id: hostField
            text: "192.168.1.13"
            placeholderText: "主机地址"
            Layout.preferredWidth: 250
        }

        TextField {
            id: portField
            text: "2250"
            placeholderText: "端口"
            validator: IntValidator { bottom: 1; top: 65535 }
            Layout.preferredWidth: 250
        }

        Item { height: 4 }

        Button {
            text: ClientWorker.connected ? "断开" : "连接"
            Layout.preferredWidth: 250
            onClicked: {
                if (ClientWorker.connected)
                    ClientWorker.disconnect()
                else
                    ClientWorker.connectToHost(hostField.text, parseInt(portField.text))
            }
        }

        Item { height: 8 }

        Frame {
            ScrollView {
                width: 400; height: 200
                TextArea {
                    id: logArea
                    readOnly: true
                    placeholderText: "连接日志..."
                    textFormat: TextEdit.AutoText
                }
            }
        }
    }

    Connections {
        target: ClientWorker
        function onConnectedChanged() {
            if (ClientWorker.connected)
                logArea.append("[%1] 已连接到 %2:%3"
                    .arg(new Date().toLocaleTimeString())
                    .arg(hostField.text)
                    .arg(portField.text))
            else
                logArea.append("[%1] 连接断开".arg(new Date().toLocaleTimeString()))
        }
    }
}
