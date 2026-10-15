#include "AppController.h"

#include <QJsonValue>
#include <QCoreApplication>
#include <QDateTime>
#include <QFileInfo>
#include <QFile>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QSettings>
#include <QSet>
#include <QQuickWindow>
#include <QGuiApplication>
#include <QStyleHints>
#include <QTimer>
#include <QEventLoop>
#include <QNetworkRequest>
#include <QNetworkProxy>
#include <cmath>
#ifdef Q_OS_WIN
#include <qt_windows.h>
#endif

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_client(this)
    , m_resourcesCatalog(this)
    , m_consumablesCatalog(this)
    , m_traitsCatalog(this)
    , m_lootCatalog(this)
    , m_weaponsCatalog(this)
{
    const auto savedLanguage = QSettings().value(QStringLiteral("ui/language"), QStringLiteral("zh")).toString();
    m_language = savedLanguage == QStringLiteral("en") ? QStringLiteral("en") : QStringLiteral("zh");
    const QSettings preferences;
    m_themeMode = preferences.value(QStringLiteral("ui/theme"), QStringLiteral("light")).toString();
    if (m_themeMode != QStringLiteral("light") && m_themeMode != QStringLiteral("dark")
        && m_themeMode != QStringLiteral("system")) qFatal("Invalid saved theme mode");
    m_reducedMotion = preferences.value(QStringLiteral("ui/reducedMotion"), false).toBool();
    m_autoRefresh = preferences.value(QStringLiteral("refresh/enabled"), true).toBool();
    m_refreshInterval = preferences.value(QStringLiteral("refresh/interval"), 1000).toInt();
    if (!QList<int>{500, 1000, 2000, 5000}.contains(m_refreshInterval)) qFatal("Invalid saved refresh interval");
    connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged, this, [this] {
        if (m_themeMode == QStringLiteral("system")) emit appearanceChanged();
    });
    m_status = m_language == QStringLiteral("zh") ? m_statusChinese : m_statusEnglish;
    QFile translations(QCoreApplication::applicationDirPath() + QStringLiteral("/translations/catalog.zh-CN.json"));
    if (!translations.open(QIODevice::ReadOnly)) {
        qFatal("Catalog translations: %s", qPrintable(translations.errorString()));
    }
    QJsonParseError translationError;
    const auto translationDocument = QJsonDocument::fromJson(translations.readAll(), &translationError);
    if (translationError.error != QJsonParseError::NoError || !translationDocument.isObject()) {
        qFatal("Catalog translations: invalid JSON (%s)", qPrintable(translationError.errorString()));
    }
    const auto categories = translationDocument.object().value(QStringLiteral("categories")).toObject();
    const QList<QPair<CatalogModel *, QString>> models{
        {&m_resourcesCatalog, QStringLiteral("resources")},
        {&m_consumablesCatalog, QStringLiteral("consumables")},
        {&m_traitsCatalog, QStringLiteral("traits")},
        {&m_lootCatalog, QStringLiteral("loot")},
        {&m_weaponsCatalog, QStringLiteral("weapons")}};
    for (const auto &model : models) {
        const auto entries = categories.value(model.second).toObject();
        if (entries.isEmpty()) qFatal("Catalog translations: missing category %s", qPrintable(model.second));
        for (auto it = entries.begin(); it != entries.end(); ++it) {
            const auto entry = it.value().toObject();
            if (entry.value(QStringLiteral("zh")).toString().trimmed().isEmpty()
                || entry.value(QStringLiteral("en")).toString().trimmed().isEmpty()) {
                qFatal("Catalog translations: incomplete entry %s", qPrintable(it.key()));
            }
        }
        model.first->setTranslations(entries);
    }
    m_refreshTimer.setInterval(m_refreshInterval);
    m_refreshTimer.setTimerType(Qt::CoarseTimer);
    connect(&m_refreshTimer, &QTimer::timeout, this, &AppController::refreshInBackground);
    connect(&m_client, &HadesToolsClient::connectionChanged, this, [this](bool connected) {
        if (!connected) {
            m_refreshTimer.stop();
        }
        if (m_connected == connected) return;
        m_connected = connected;
        emit connectedChanged();
    });
    connect(&m_client, &HadesToolsClient::probeFailed, this, [this](const QString &message) {
        m_connecting = false;
        m_hasError = true;
        emit busyChanged();
        setStatus(QStringLiteral("连接失败：%1").arg(message), QStringLiteral("Connection failed: %1").arg(message));
        appendLog(QStringLiteral("connect"), QStringLiteral("Hades"), QStringLiteral("error"), message);
    });
    connect(&m_client, &HadesToolsClient::commandFailed, this,
            [this](const QJsonObject &command, const QString &message, bool background) {
        const auto action = command.value(QStringLiteral("action")).toString();
        if (background) {
            m_refreshTimer.stop();
            m_hasError = true;
            const bool snapshot = action == QStringLiteral("snapshot");
            setStatus(snapshot ? QStringLiteral("自动刷新已停止：%1").arg(message)
                               : QStringLiteral("目录读取失败：%1").arg(message),
                      snapshot ? QStringLiteral("Automatic refresh stopped: %1").arg(message)
                               : QStringLiteral("Catalog read failed: %1").arg(message));
            appendLog(snapshot ? QStringLiteral("auto_refresh") : action,
                      describeCommand(command), QStringLiteral("error"), message);
            return;
        }
        m_connecting = false;
        m_hasError = true;
        emit busyChanged();
        setStatus(QStringLiteral("任务失败：%1").arg(message), QStringLiteral("Task failed: %1").arg(message));
        appendLog(action == QStringLiteral("session_start") ? QStringLiteral("connect") : action,
                  describeCommand(command), QStringLiteral("error"), message);
    });
    connect(&m_client, &HadesToolsClient::commandCancelled, this,
            [this](const QJsonObject &command, const QString &message, bool) {
        appendLog(command.value(QStringLiteral("action")).toString(), describeCommand(command),
                  QStringLiteral("cancelled"), message);
    });
    connect(&m_client, &HadesToolsClient::busyChanged, this, [this](bool busy) {
        m_busy = busy;
        emit busyChanged();
    });
    connect(&m_client, &HadesToolsClient::serviceAvailable, this, &AppController::startSession);
    connect(&m_client, &HadesToolsClient::serviceMissing, this, &AppController::startBackend);
    connect(&m_client, &HadesToolsClient::commandSucceeded, this,
            [this](const QJsonObject &command, const QJsonObject &value, bool background) {
        const auto action = command.value(QStringLiteral("action")).toString();
        if (value.value(QStringLiteral("hero")).isObject()) applySnapshot(value);
        if (value.contains(QStringLiteral("resources")) && value.contains(QStringLiteral("consumables"))) applyCatalog(value);
        if (background) return;

        m_hasError = false;
        if (action == QStringLiteral("session_start")) {
            m_sessionStarted = true;
            m_connecting = false;
            emit busyChanged();
            sendInternal(QJsonObject{{QStringLiteral("action"), QStringLiteral("catalog")}});
            sendInternal(QJsonObject{{QStringLiteral("action"), QStringLiteral("snapshot")}});
            updateRefreshTimer();
            for (auto *window : QGuiApplication::allWindows()) {
                window->raise();
                window->requestActivate();
            }
        }
        const auto result = value.value(QStringLiteral("command")).toObject();
        if (action.startsWith(QStringLiteral("spawn_"))) {
            m_lastObjectId = result.value(QStringLiteral("objectId")).toInt();
            emit snapshotChanged();
        }
        if (action == QStringLiteral("snapshot")) updateRefreshTimer();
        const auto objectId = result.value(QStringLiteral("objectId")).toInt();
        setStatus(result.contains(QStringLiteral("objectId"))
                      ? QStringLiteral("任务完成 · 对象 ID：%1").arg(objectId)
                      : QStringLiteral("游戏已连接 · 任务完成"),
                  result.contains(QStringLiteral("objectId"))
                      ? QStringLiteral("Task completed · Object ID: %1").arg(objectId)
                      : QStringLiteral("Game connected · Task completed"));
        appendLog(action == QStringLiteral("session_start") ? QStringLiteral("connect") : action,
                  describeCommand(command), QStringLiteral("success"),
                  result.contains(QStringLiteral("objectId")) ? QStringLiteral("Object ID: %1").arg(objectId) : QString());
    });
    connect(&m_backend, &QProcess::readyReadStandardOutput, this, [this] {
        m_backendOutput += m_backend.readAllStandardOutput();
        if (m_backendOutput.size() > 65536) m_backendOutput = m_backendOutput.right(65536);
        if (m_connecting && m_backendOutput.contains("HADES_TOOLS_READY")) {
            m_backendOutput.clear();
            startSession();
        }
    });
    connect(&m_backend, &QProcess::errorOccurred, this, [this] {
        m_hasError = true;
        m_connecting = false;
        const auto message = m_backend.errorString();
        setStatus(QStringLiteral("连接服务错误：%1").arg(message), QStringLiteral("Bridge error: %1").arg(message));
        appendLog(QStringLiteral("connect"), QStringLiteral("Hades"), QStringLiteral("error"), message);
        emit busyChanged();
    });
    connect(&m_backend, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int code, QProcess::ExitStatus) {
        m_connected = false;
        m_sessionStarted = false;
        m_connecting = false;
        m_hasError = true;
        m_refreshTimer.stop();
        const auto message = QString::fromUtf8(m_backend.readAllStandardError()).trimmed();
        setStatus(QStringLiteral("游戏连接服务已退出 (%1)：%2").arg(code).arg(message),
                  QStringLiteral("Game bridge exited (%1): %2").arg(code).arg(message));
        appendLog(QStringLiteral("bridge_exit"), QStringLiteral("Exit code %1").arg(code), QStringLiteral("error"), message);
        emit connectedChanged();
        emit busyChanged();
    });
}

AppController::~AppController()
{
    m_refreshTimer.stop();
    m_client.stop();
    disconnect(&m_client, nullptr, this, nullptr);
    disconnect(&m_backend, nullptr, this, nullptr);
    const bool ownsBackend = m_backend.state() != QProcess::NotRunning;
    if (ownsBackend || m_sessionStarted) {
        QNetworkAccessManager network;
        network.setProxy(QNetworkProxy::NoProxy);
        QNetworkRequest request(QUrl(ownsBackend
            ? QStringLiteral("http://127.0.0.1:27864/api/shutdown")
            : QStringLiteral("http://127.0.0.1:27864/api/command")));
        request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
        request.setTransferTimeout(1500);
        auto *reply = network.post(request, ownsBackend ? QByteArrayLiteral("{}")
                                   : QByteArrayLiteral("{\"action\":\"session_end\"}"));
        QEventLoop loop;
        connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
        loop.exec();
        if (reply->error() != QNetworkReply::NoError) qWarning() << "Session cleanup:" << reply->errorString();
    }
    if (ownsBackend) {
        if (!m_backend.waitForFinished(12000)) qWarning() << "Bridge cleanup timed out";
        qInfo().noquote() << QString::fromUtf8(m_backendOutput + m_backend.readAllStandardOutput()).trimmed();
        const auto errors = m_backend.readAllStandardError();
        if (!errors.isEmpty()) qWarning().noquote() << QString::fromUtf8(errors).trimmed();
    }
}

void AppController::connectToGame()
{
    if (busy()) return;
    m_refreshTimer.stop();
    m_connecting = true;
    m_hasError = false;
    setStatus(QStringLiteral("正在连接游戏…"), QStringLiteral("Connecting to Hades…"));
    emit busyChanged();
    m_client.probe();
}

void AppController::startBackend()
{
    const auto executable = QCoreApplication::applicationDirPath() + QStringLiteral("/bridge/HadesToolsBridge.exe");
    if (!QFileInfo::exists(executable)) {
        m_connecting = false;
        m_hasError = true;
        setStatus(QStringLiteral("缺少游戏连接服务：%1").arg(executable),
                  QStringLiteral("Game bridge is missing: %1").arg(executable));
        appendLog(QStringLiteral("connect"), QStringLiteral("Hades"), QStringLiteral("error"), executable);
        emit busyChanged();
        return;
    }
    m_backendOutput.clear();
    m_backend.start(executable, {QStringLiteral("--parent-pid"), QString::number(QCoreApplication::applicationPid())});
}

void AppController::startSession()
{
#ifdef Q_OS_WIN
    HWND game = FindWindowW(nullptr, L"Hades");
    if (!game) {
        m_connecting = false;
        m_hasError = true;
        setStatus(QStringLiteral("请先启动 Hades 并加载存档。"),
                  QStringLiteral("Start Hades and load a save first."));
        appendLog(QStringLiteral("connect"), QStringLiteral("Hades"), QStringLiteral("error"),
                  QStringLiteral("Hades window was not found"));
        emit busyChanged();
        return;
    }
    ShowWindow(game, SW_RESTORE);
    SetForegroundWindow(game);
#endif
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("session_start")}});
}

void AppController::destroyObject(double objectId)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("destroy_object")}, {QStringLiteral("objectId"), objectId}});
}

bool AppController::connected() const { return m_connected; }
QString AppController::status() const { return m_status; }
QVariantMap AppController::hero() const { return m_hero; }
QVariantMap AppController::ragebot() const { return m_ragebot; }
QVariantMap AppController::run() const { return m_run; }
QVariantMap AppController::resources() const { return m_resources; }
CatalogModel *AppController::resourcesCatalog() { return &m_resourcesCatalog; }
CatalogModel *AppController::consumablesCatalog() { return &m_consumablesCatalog; }
CatalogModel *AppController::traitsCatalog() { return &m_traitsCatalog; }
CatalogModel *AppController::lootCatalog() { return &m_lootCatalog; }
CatalogModel *AppController::weaponsCatalog() { return &m_weaponsCatalog; }

void AppController::refresh() { send(QJsonObject{{QStringLiteral("action"), QStringLiteral("snapshot")}}); }

void AppController::setLanguage(const QString &language)
{
    const auto normalized = language == QStringLiteral("en") ? QStringLiteral("en") : QStringLiteral("zh");
    if (m_language == normalized) return;
    m_language = normalized;
    QSettings().setValue(QStringLiteral("ui/language"), m_language);
    m_status = m_language == QStringLiteral("zh") ? m_statusChinese : m_statusEnglish;
    emit languageChanged();
    emit statusChanged();
}

void AppController::clearLogs()
{
    if (m_logs.isEmpty()) return;
    m_logs.clear();
    emit logsChanged();
}

bool AppController::darkTheme() const
{
    return m_themeMode == QStringLiteral("dark")
        || (m_themeMode == QStringLiteral("system")
            && QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Dark);
}

void AppController::setThemeMode(const QString &mode)
{
    if (mode != QStringLiteral("light") && mode != QStringLiteral("dark") && mode != QStringLiteral("system")) {
        qWarning() << "Invalid theme mode:" << mode;
        return;
    }
    if (m_themeMode == mode) return;
    m_themeMode = mode;
    QSettings().setValue(QStringLiteral("ui/theme"), mode);
    emit themeModeChanged();
    emit appearanceChanged();
}

void AppController::setReducedMotion(bool reduced)
{
    if (m_reducedMotion == reduced) return;
    m_reducedMotion = reduced;
    QSettings().setValue(QStringLiteral("ui/reducedMotion"), reduced);
    emit reducedMotionChanged();
}

void AppController::setAutoRefresh(bool enabled)
{
    if (m_autoRefresh == enabled) return;
    m_autoRefresh = enabled;
    QSettings().setValue(QStringLiteral("refresh/enabled"), enabled);
    updateRefreshTimer();
    emit refreshPreferencesChanged();
}

void AppController::setRefreshInterval(int milliseconds)
{
    if (!QList<int>{500, 1000, 2000, 5000}.contains(milliseconds)) {
        qWarning() << "Invalid refresh interval:" << milliseconds;
        return;
    }
    if (m_refreshInterval == milliseconds) return;
    m_refreshInterval = milliseconds;
    m_refreshTimer.setInterval(milliseconds);
    QSettings().setValue(QStringLiteral("refresh/interval"), milliseconds);
    emit refreshPreferencesChanged();
}

void AppController::updateRefreshTimer()
{
    if (m_autoRefresh && m_connected && m_sessionStarted && !m_hasError && !m_connecting)
        m_refreshTimer.start();
    else m_refreshTimer.stop();
}

void AppController::setGod(bool enabled)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("god")}, {QStringLiteral("value"), enabled}});
}

void AppController::setInfiniteCast(bool enabled)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("infinite_cast")}, {QStringLiteral("value"), enabled}});
}

void AppController::setRagebotOption(const QString &option, bool enabled)
{
    static const QSet<QString> options{QStringLiteral("autoAim"), QStringLiteral("autoFire"), QStringLiteral("silentShot"), QStringLiteral("lockHold"), QStringLiteral("syncWeapons"), QStringLiteral("perfectBow")};
    if (!options.contains(option)) {
        qWarning() << "Invalid ragebot option:" << option;
        return;
    }
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("ragebot_option")},
                     {QStringLiteral("option"), option},
                     {QStringLiteral("value"), enabled}});
}

void AppController::setRagebotMode(const QString &option, const QString &value)
{
    static const QSet<QString> priorities{QStringLiteral("nearest"), QStringLiteral("lowest_health"), QStringLiteral("elite"), QStringLiteral("boss")};
    static const QSet<QString> spreads{QStringLiteral("off"), QStringLiteral("seed_check"), QStringLiteral("remove_spread")};
    if (option == QStringLiteral("targetPriority") && !priorities.contains(value)) {
        qWarning() << "Invalid ragebot target priority:" << value;
        return;
    }
    if (option == QStringLiteral("spreadMode") && !spreads.contains(value)) {
        qWarning() << "Invalid ragebot spread mode:" << value;
        return;
    }
    if (option != QStringLiteral("targetPriority") && option != QStringLiteral("spreadMode")) {
        qWarning() << "Invalid ragebot mode:" << option;
        return;
    }
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("ragebot_mode")},
                     {QStringLiteral("option"), option},
                     {QStringLiteral("value"), value}});
}

void AppController::setNumber(const QString &action, double value)
{
    send(QJsonObject{{QStringLiteral("action"), action}, {QStringLiteral("value"), value}});
}

void AppController::setDashCount(double value)
{
    setNumber(QStringLiteral("dash_count"), value);
}

void AppController::setAttribute(const QString &name, double value)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("attribute")}, {QStringLiteral("name"), name}, {QStringLiteral("value"), value}});
}

void AppController::setResource(const QString &name, double value)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("resource")}, {QStringLiteral("name"), name}, {QStringLiteral("value"), value}});
}

void AppController::spawn(const QString &action, const QString &name, const QString &rarity)
{
    QJsonObject command{{QStringLiteral("action"), action}, {QStringLiteral("name"), name}};
    if (!rarity.isEmpty()) command.insert(QStringLiteral("rarity"), rarity);
    send(command);
}

void AppController::selectWeapon(const QString &name)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("weapon")}, {QStringLiteral("name"), name}});
}

void AppController::setTraitLevel(const QString &name, double value)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("trait_property")},
                     {QStringLiteral("name"), name},
                     {QStringLiteral("property"), QStringLiteral("StackNum")},
                     {QStringLiteral("value"), value}});
}

void AppController::setTraitRarity(const QString &name, const QString &rarity)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("trait_rarity")},
                     {QStringLiteral("name"), name},
                     {QStringLiteral("rarity"), rarity}});
}

void AppController::setWeaponProperty(const QString &name, const QString &property, double value)
{
    send(QJsonObject{{QStringLiteral("action"), QStringLiteral("weapon_property")},
                     {QStringLiteral("name"), name},
                     {QStringLiteral("property"), property},
                     {QStringLiteral("value"), value}});
}

void AppController::send(const QJsonObject &command)
{
    if (command.contains(QStringLiteral("value")) &&
        (command.value(QStringLiteral("value")).isNull() ||
        (command.value(QStringLiteral("value")).isDouble() && !std::isfinite(command.value(QStringLiteral("value")).toDouble())))) {
        m_hasError = true;
        setStatus(QStringLiteral("请输入有效数字。"), QStringLiteral("Enter a valid number."));
        appendLog(command.value(QStringLiteral("action")).toString(), describeCommand(command),
                  QStringLiteral("error"), QStringLiteral("Invalid numeric value"));
        return;
    }
    m_hasError = false;
    setStatus(QStringLiteral("正在执行任务…"), QStringLiteral("Running task…"));
    m_client.command(command);
}

void AppController::sendInternal(const QJsonObject &command)
{
    m_client.command(command, true);
}

void AppController::refreshInBackground()
{
    if (!m_autoRefresh || !m_connected || !m_sessionStarted || !m_client.isIdle()) return;
    sendInternal(QJsonObject{{QStringLiteral("action"), QStringLiteral("snapshot")}});
}

void AppController::applySnapshot(const QJsonObject &snapshot)
{
    const auto nextHero = snapshot.value(QStringLiteral("hero")).toObject().toVariantMap();
    const auto nextRun = snapshot.value(QStringLiteral("run")).toObject().toVariantMap();
    const bool changedActor = (!m_hero.isEmpty() && m_hero.value(QStringLiteral("objectId")) != nextHero.value(QStringLiteral("objectId")))
                           || (!m_run.isEmpty() && m_run.value(QStringLiteral("room")) != nextRun.value(QStringLiteral("room")));
    m_hero = nextHero;
    m_ragebot = snapshot.value(QStringLiteral("ragebot")).toObject().toVariantMap();
    m_run = nextRun;
    m_resources = snapshot.value(QStringLiteral("resources")).toObject().toVariantMap();
    if (changedActor) m_lastObjectId = 0;
    m_lastUpdated = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    emit lastUpdatedChanged();
    emit snapshotChanged();
}

void AppController::applyCatalog(const QJsonObject &catalog)
{
    m_resourcesCatalog.setRows(catalog.value(QStringLiteral("resources")).toArray());
    m_consumablesCatalog.setRows(catalog.value(QStringLiteral("consumables")).toArray());
    m_traitsCatalog.setRows(catalog.value(QStringLiteral("traits")).toArray());
    m_lootCatalog.setRows(catalog.value(QStringLiteral("loot")).toArray());
    QJsonArray heroWeapons;
    for (const auto &weapon : catalog.value(QStringLiteral("weapons")).toArray()) {
        if (weapon.toObject().value(QStringLiteral("heroWeapon")).toBool()) heroWeapons.append(weapon);
    }
    m_weaponsCatalog.setRows(heroWeapons);
    emit catalogChanged();
}

void AppController::setStatus(const QString &chinese, const QString &english)
{
    m_statusChinese = chinese;
    m_statusEnglish = english;
    const auto status = m_language == QStringLiteral("zh") ? chinese : english;
    m_status = status;
    emit statusChanged();
}

void AppController::appendLog(const QString &action, const QString &details, const QString &outcome, const QString &message)
{
    QVariantMap entry;
    entry.insert(QStringLiteral("timestamp"), QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss")));
    entry.insert(QStringLiteral("action"), action.isEmpty() ? QStringLiteral("unknown") : action);
    entry.insert(QStringLiteral("details"), details);
    entry.insert(QStringLiteral("outcome"), outcome);
    entry.insert(QStringLiteral("message"), message);
    m_logs.prepend(entry);
    while (m_logs.size() > 300) m_logs.removeLast();
    emit logsChanged();
}

QString AppController::describeCommand(const QJsonObject &command) const
{
    const auto action = command.value(QStringLiteral("action")).toString();
    if (action == QStringLiteral("session_start") || action == QStringLiteral("snapshot") || action == QStringLiteral("heal")) return QStringLiteral("Hades");
    if (action == QStringLiteral("dash_count")) return QStringLiteral("Dash count");
    if (action == QStringLiteral("super_meter")) return QStringLiteral("Super meter");
    if (action == QStringLiteral("god")) return command.value(QStringLiteral("value")).toBool() ? QStringLiteral("ON") : QStringLiteral("OFF");
    if (action == QStringLiteral("infinite_cast")) return command.value(QStringLiteral("value")).toBool() ? QStringLiteral("ON") : QStringLiteral("OFF");
    if (action == QStringLiteral("ragebot_option")) {
        return QStringLiteral("%1 = %2").arg(command.value(QStringLiteral("option")).toString(),
                                             command.value(QStringLiteral("value")).toBool() ? QStringLiteral("ON") : QStringLiteral("OFF"));
    }
    if (command.contains(QStringLiteral("objectId"))) return QStringLiteral("ID %1").arg(command.value(QStringLiteral("objectId")).toDouble(), 0, 'g', 16);

    QStringList parts;
    if (command.contains(QStringLiteral("name"))) parts.append(command.value(QStringLiteral("name")).toString());
    if (command.contains(QStringLiteral("property"))) parts.append(command.value(QStringLiteral("property")).toString());
    if (command.contains(QStringLiteral("value"))) parts.append(QStringLiteral("= %1").arg(command.value(QStringLiteral("value")).toDouble(), 0, 'g', 16));
    if (command.contains(QStringLiteral("rarity")) && !command.value(QStringLiteral("rarity")).toString().isEmpty()) {
        parts.append(QStringLiteral("[%1]").arg(command.value(QStringLiteral("rarity")).toString()));
    }
    return parts.join(QLatin1Char(' '));
}
