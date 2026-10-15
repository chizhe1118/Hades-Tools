#pragma once

#include <QObject>
#include <QJsonObject>
#include <QJsonDocument>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrl>
#include <QQueue>

class HadesToolsClient final : public QObject
{
    Q_OBJECT

public:
    explicit HadesToolsClient(QObject *parent = nullptr);

    void command(const QJsonObject &command, bool background = false);
    void probe();
    void stop();
    bool isIdle() const;
    QUrl baseUrl() const;

signals:
    void commandSucceeded(const QJsonObject &command, const QJsonObject &response, bool background);
    void commandFailed(const QJsonObject &command, const QString &message, bool background);
    void commandCancelled(const QJsonObject &command, const QString &message, bool background);
    void probeFailed(const QString &message);
    void connectionChanged(bool connected);
    void busyChanged(bool busy);
    void serviceAvailable();
    void serviceMissing();

private:
    struct Request {
        QJsonObject command;
        bool background{false};
    };

    QNetworkAccessManager m_network;
    QUrl m_baseUrl{QStringLiteral("http://127.0.0.1:27864")};
    QQueue<Request> m_pending;
    bool m_active{false};
    bool m_stopping{false};
    int m_foregroundPending{0};

    void sendNext();
    void finishRequest(const Request &request, bool clearPending, const QString &reason = {});
};
