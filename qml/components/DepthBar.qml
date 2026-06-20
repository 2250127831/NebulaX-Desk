import QtQuick
import QtQuick.Controls
import NebulaX.Desk

Rectangle {
    id: root

    property string side: "bid"
    property int volume: 0
    property int maxVolume: 1
    property int price: 0

    readonly property color barColor: side === "bid" ? Theme.buyGreen : Theme.sellRed
    readonly property color barDim:   side === "bid" ? Theme.buyDim : Theme.sellDim

    height: 28
    radius: Theme.radiusSm
    color: Theme.bgCard
    clip: true

    // Depth fill bar
    Rectangle {
        id: fillBar
        height: parent.height
        width: maxVolume > 0 ? (root.volume / root.maxVolume) * parent.width : 0
        radius: Theme.radiusSm
        color: root.barColor
        opacity: 0.3

        Behavior on width { NumberAnimation { duration: Theme.animNorm; easing.type: Easing.OutCubic } }

        // Shimmer breathing overlay
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: Qt.rgba(1, 1, 1, shimmer * 0.06)
            property real shimmer: 0.0
            SequentialAnimation on shimmer {
                loops: Animation.Infinite
                NumberAnimation { from: 0.0; to: 1.0; duration: Theme.animBreath * 2; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.0; to: 0.0; duration: Theme.animBreath * 2; easing.type: Easing.InOutSine }
            }
        }
    }

    // Price label
    Label {
        anchors.left: parent.left; anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: String(root.price)
        color: root.barColor
        font.pixelSize: Theme.fontSizeSm
        font.family: Theme.fontMono
        font.bold: true
    }

    // Volume label
    Label {
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: String(root.volume)
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeXs
        font.family: Theme.fontMono
    }
}
