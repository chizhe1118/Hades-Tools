#include "AppController.h"
#include "WindowAppearance.h"
#include "stylemanager.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSurfaceFormat>
#include <QFont>
#include <QQuickWindow>
#include <QStyleHints>

int main(int argc, char *argv[])
{
    QSurfaceFormat format;
    format.setSamples(4);
    QSurfaceFormat::setDefaultFormat(format);
    QQuickWindow::setTextRenderType(QQuickWindow::NativeTextRendering);

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Hades Tools"));
    app.setApplicationVersion(QStringLiteral("0.2.6"));
    app.setOrganizationName(QStringLiteral("Hades Tools"));
    AppController controller;
    const auto applyFont = [&app, &controller] {
        const bool chinese = controller.language() == QStringLiteral("zh");
        QFont font(chinese ? QStringLiteral("SimSun") : QStringLiteral("Segoe UI"), 10);
        font.setWeight(chinese ? QFont::Bold : QFont::Normal);
        app.setFont(font);
    };
    applyFont();
    QObject::connect(&controller, &AppController::languageChanged, &app, applyFont);
    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    engine.rootContext()->setContextProperty(QStringLiteral("AppController"), &controller);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] {
        QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.loadFromModule(QStringLiteral("hades.Tools"), QStringLiteral("Main"));
    if (!engine.rootObjects().isEmpty()) {
        // The application owns explicit light/dark/system preference handling.
        auto *style = engine.singletonInstance<StyleManager *>("md3.Core", "StyleManager");
        if (!style) qFatal("MD3 StyleManager singleton is missing");
        QObject::disconnect(app.styleHints(), &QStyleHints::colorSchemeChanged, style, nullptr);
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        if (!window) qFatal("Application root is not a QQuickWindow");
        auto *appearance = new WindowAppearance(window);
        appearance->setDark(controller.darkTheme());
        QObject::connect(&controller, &AppController::appearanceChanged, appearance,
                         [appearance, &controller] { appearance->setDark(controller.darkTheme()); });
    }
    return app.exec();
}
