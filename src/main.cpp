#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "ClientWorker.h"

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);

    ClientWorker worker;
    QQmlApplicationEngine engine;

    qmlRegisterSingletonInstance("NebulaX.Desk", 1, 0, "ClientWorker", &worker);

    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    return app.exec();
}
