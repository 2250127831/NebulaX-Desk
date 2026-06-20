#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <cstdlib>
#include "ClientWorker.h"

int main(int argc, char* argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Fusion");
    QGuiApplication app(argc, argv);

    ClientWorker worker;
    QQmlApplicationEngine engine;

    // Theme singleton — create QObject directly, register as instance
    {
        static const char qml[] = R"(
import QtQuick;
QtObject {
    readonly property color bgDeep:        "#0E0E12"
    readonly property color bgCard:        "#1A1A24"
    readonly property color bgElevated:    "#22222E"
    readonly property color bgHover:       "#2A2A38"
    readonly property color borderLight:   "#2E2E3E"
    readonly property color borderFocus:   "#3A3A4E"
    readonly property color accent:        "#F0B90B"
    readonly property color accentDim:     "#C4920A"
    readonly property color buyGreen:      "#0ECB81"
    readonly property color buyDim:        "#0A9E66"
    readonly property color sellRed:       "#F6465D"
    readonly property color sellDim:       "#C4384A"
    readonly property color textPrimary:   "#EAEAEA"
    readonly property color textSecondary: "#848E9C"
    readonly property color textMuted:     "#5E6673"
    readonly property color textAccent:    "#F0B90B"
    readonly property color statusOpen:    "#F0B90B"
    readonly property color statusPartial: "#2D95F3"
    readonly property color statusFilled:  "#0ECB81"
    readonly property color statusCancel:  "#848E9C"
    readonly property color statusError:   "#F6465D"
    readonly property int    fontSizeXs:   10
    readonly property int    fontSizeSm:   11
    readonly property int    fontSizeMd:   13
    readonly property int    fontSizeLg:   16
    readonly property int    fontSizeXl:   20
    readonly property int    fontSizeXxl:  28
    readonly property string fontMono:     "Consolas, Courier New, monospace"
    readonly property int    spacingXs:    4
    readonly property int    spacingSm:    8
    readonly property int    spacingMd:    12
    readonly property int    spacingLg:    16
    readonly property int    spacingXl:    24
    readonly property int    radiusSm:     4
    readonly property int    radiusMd:     8
    readonly property int    radiusLg:     12
    readonly property int    animFast:     150
    readonly property int    animNorm:     300
    readonly property int    animSlow:     600
    readonly property int    animBreath:   3000
})";
        QQmlComponent themeComponent(&engine);
        themeComponent.setData(QByteArray(qml), QUrl());
        QObject* theme = themeComponent.create();
        if (theme)
            qmlRegisterSingletonInstance("NebulaX.Desk", 1, 0, "Theme", theme);
    }

    qmlRegisterSingletonInstance("NebulaX.Desk", 1, 0, "ClientWorker", &worker);

    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    return app.exec();
}
