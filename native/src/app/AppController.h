#pragma once

#include "CatalogModel.h"
#include "HadesToolsClient.h"

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class AppController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool hasError READ hasError NOTIFY statusChanged)
    Q_PROPERTY(int lastObjectId READ lastObjectId NOTIFY snapshotChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)
    Q_PROPERTY(bool darkTheme READ darkTheme NOTIFY appearanceChanged)
    Q_PROPERTY(bool reducedMotion READ reducedMotion WRITE setReducedMotion NOTIFY reducedMotionChanged)
    Q_PROPERTY(bool autoRefresh READ autoRefresh WRITE setAutoRefresh NOTIFY refreshPreferencesChanged)
    Q_PROPERTY(int refreshInterval READ refreshInterval WRITE setRefreshInterval NOTIFY refreshPreferencesChanged)
    Q_PROPERTY(QString lastUpdated READ lastUpdated NOTIFY lastUpdatedChanged)
    Q_PROPERTY(QVariantList logs READ logs NOTIFY logsChanged)
    Q_PROPERTY(QVariantMap hero READ hero NOTIFY snapshotChanged)
    Q_PROPERTY(QVariantMap ragebot READ ragebot NOTIFY snapshotChanged)
    Q_PROPERTY(QVariantMap run READ run NOTIFY snapshotChanged)
    Q_PROPERTY(QVariantMap resources READ resources NOTIFY snapshotChanged)
    Q_PROPERTY(CatalogModel *resourcesCatalog READ resourcesCatalog CONSTANT)
    Q_PROPERTY(CatalogModel *consumablesCatalog READ consumablesCatalog CONSTANT)
    Q_PROPERTY(CatalogModel *traitsCatalog READ traitsCatalog CONSTANT)
    Q_PROPERTY(CatalogModel *lootCatalog READ lootCatalog CONSTANT)
    Q_PROPERTY(CatalogModel *weaponsCatalog READ weaponsCatalog CONSTANT)

public:
    explicit AppController(QObject *parent = nullptr);
    ~AppController() override;

    bool connected() const;
    bool busy() const { return m_busy || m_connecting; }
    bool hasError() const { return m_hasError; }
    int lastObjectId() const { return m_lastObjectId; }
    QString status() const;
    QString language() const { return m_language; }
    QString themeMode() const { return m_themeMode; }
    bool darkTheme() const;
    bool reducedMotion() const { return m_reducedMotion; }
    bool autoRefresh() const { return m_autoRefresh; }
    int refreshInterval() const { return m_refreshInterval; }
    QString lastUpdated() const { return m_lastUpdated; }
    QVariantList logs() const { return m_logs; }
    QVariantMap hero() const;
    QVariantMap ragebot() const;
    QVariantMap run() const;
    QVariantMap resources() const;
    CatalogModel *resourcesCatalog();
    CatalogModel *consumablesCatalog();
    CatalogModel *traitsCatalog();
    CatalogModel *lootCatalog();
    CatalogModel *weaponsCatalog();

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void connectToGame();
    Q_INVOKABLE void setLanguage(const QString &language);
    Q_INVOKABLE void setThemeMode(const QString &mode);
    Q_INVOKABLE void setReducedMotion(bool reduced);
    Q_INVOKABLE void setAutoRefresh(bool enabled);
    Q_INVOKABLE void setRefreshInterval(int milliseconds);
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE void destroyObject(double objectId);
    Q_INVOKABLE void setGod(bool enabled);
    Q_INVOKABLE void setInfiniteCast(bool enabled);
    Q_INVOKABLE void setRagebotOption(const QString &option, bool enabled);
    Q_INVOKABLE void setRagebotMode(const QString &option, const QString &value);
    Q_INVOKABLE void setNumber(const QString &action, double value);
    Q_INVOKABLE void setDashCount(double value);
    Q_INVOKABLE void setAttribute(const QString &name, double value);
    Q_INVOKABLE void setResource(const QString &name, double value);
    Q_INVOKABLE void spawn(const QString &action, const QString &name, const QString &rarity = {});
    Q_INVOKABLE void selectWeapon(const QString &name);
    Q_INVOKABLE void setTraitLevel(const QString &name, double value);
    Q_INVOKABLE void setTraitRarity(const QString &name, const QString &rarity);
    Q_INVOKABLE void setWeaponProperty(const QString &name, const QString &property, double value);

signals:
    void connectedChanged();
    void busyChanged();
    void statusChanged();
    void languageChanged();
    void themeModeChanged();
    void appearanceChanged();
    void reducedMotionChanged();
    void refreshPreferencesChanged();
    void lastUpdatedChanged();
    void logsChanged();
    void snapshotChanged();
    void catalogChanged();

private:
    void send(const QJsonObject &command);
    void sendInternal(const QJsonObject &command);
    void refreshInBackground();
    void updateRefreshTimer();
    void applySnapshot(const QJsonObject &snapshot);
    void applyCatalog(const QJsonObject &catalog);
    void setStatus(const QString &chinese, const QString &english);
    void appendLog(const QString &action, const QString &details, const QString &outcome, const QString &message = {});
    QString describeCommand(const QJsonObject &command) const;
    void startSession();
    void startBackend();

    HadesToolsClient m_client;
    bool m_connected{false};
    bool m_busy{false};
    bool m_connecting{false};
    bool m_hasError{false};
    bool m_sessionStarted{false};
    int m_lastObjectId{0};
    QProcess m_backend;
    QTimer m_refreshTimer;
    QByteArray m_backendOutput;
    QString m_language{QStringLiteral("zh")};
    QString m_themeMode{QStringLiteral("light")};
    bool m_reducedMotion{false};
    bool m_autoRefresh{true};
    int m_refreshInterval{1000};
    QString m_status;
    QString m_statusChinese{QStringLiteral("启动游戏并加载存档，然后点击连接游戏。")} ;
    QString m_statusEnglish{QStringLiteral("Start Hades, load a save, then connect to the game.")} ;
    QString m_lastUpdated;
    QVariantList m_logs;
    QVariantMap m_hero;
    QVariantMap m_ragebot;
    QVariantMap m_run;
    QVariantMap m_resources;
    CatalogModel m_resourcesCatalog;
    CatalogModel m_consumablesCatalog;
    CatalogModel m_traitsCatalog;
    CatalogModel m_lootCatalog;
    CatalogModel m_weaponsCatalog;
};
