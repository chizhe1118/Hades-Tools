#include "HadesToolsClient.h"

#include <QNetworkRequest>
#include <QNetworkProxy>

HadesToolsClient::HadesToolsClient(QObject *parent)
    : QObject(parent)
{
    m_network.setProxy(QNetworkProxy::NoProxy);
}

QUrl HadesToolsClient::baseUrl() const
{
    return m_baseUrl;
}

void HadesToolsClient::command(const QJsonObject &commandObject, bool background)
{
    if (m_stopping) return;
    m_pending.enqueue(Request{commandObject, background});
    if (!background && m_foregroundPending++ == 0) {
        emit busyChanged(true);
    }
    if (!m_active) {
        sendNext();
    }
}

bool HadesToolsClient::isIdle() const
{
    return !m_active && m_pending.isEmpty();
}

void HadesToolsClient::stop()
{
    m_stopping = true;
    m_pending.clear();
    for (auto *reply : m_network.findChildren<QNetworkReply *>()) reply->abort();
}

void HadesToolsClient::probe()
{
    QNetworkRequest request(m_baseUrl.resolved(QUrl(QStringLiteral("/api/info"))));
    request.setTransferTimeout(10000);
    auto *reply = m_network.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        if (m_stopping) {
            reply->deleteLater();
            return;
        }
        if (reply->error() == QNetworkReply::ConnectionRefusedError) {
            emit serviceMissing();
        } else if (reply->error() != QNetworkReply::NoError) {
            emit probeFailed(reply->errorString());
        } else {
            const auto info = QJsonDocument::fromJson(reply->readAll()).object();
            if (!info.contains(QStringLiteral("luaState")))
                emit probeFailed(QStringLiteral("Port 27864 is occupied by another service"));
            else emit serviceAvailable();
        }
        reply->deleteLater();
    });
}

void HadesToolsClient::sendNext()
{
    if (m_stopping) return;
    if (m_pending.isEmpty()) {
        m_active = false;
        return;
    }
    m_active = true;
    const auto requestData = m_pending.dequeue();
    QNetworkRequest request(m_baseUrl.resolved(QUrl(QStringLiteral("/api/command"))));
    request.setTransferTimeout(12000);
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    auto *reply = m_network.post(request, QJsonDocument(requestData.command).toJson(QJsonDocument::Compact));

    connect(reply, &QNetworkReply::finished, this, [this, reply, requestData]() {
        if (m_stopping) {
            reply->deleteLater();
            return;
        }
        connect(reply, &QObject::destroyed, this, [this] {
            m_active = false;
            sendNext();
        });
        const QByteArray payload = reply->readAll();
        const auto networkError = reply->error();
        QJsonParseError parseError{};
        const QJsonDocument document = QJsonDocument::fromJson(payload, &parseError);
        const auto response = document.object();
        // Command errors use HTTP 400 and carry the game error in JSON.
        if (document.isObject() && response.contains(QStringLiteral("ok")) && !response.value(QStringLiteral("ok")).toBool()) {
            emit connectionChanged(true);
            finishRequest(requestData, true, response.value(QStringLiteral("error")).toString());
            emit commandFailed(requestData.command, response.value(QStringLiteral("error")).toString(), requestData.background);
            reply->deleteLater();
            return;
        }
        if (networkError != QNetworkReply::NoError) {
            emit connectionChanged(false);
            finishRequest(requestData, true, reply->errorString());
            emit commandFailed(requestData.command, reply->errorString(), requestData.background);
            reply->deleteLater();
            return;
        }
        if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
            emit connectionChanged(false);
            finishRequest(requestData, true, QStringLiteral("Invalid GM response"));
            emit commandFailed(requestData.command,
                               QStringLiteral("Invalid GM response: %1").arg(parseError.errorString()),
                               requestData.background);
            reply->deleteLater();
            return;
        }

        if (!response.value(QStringLiteral("ok")).toBool()) {
            emit connectionChanged(false);
            finishRequest(requestData, true, QStringLiteral("GM response has no success status"));
            emit commandFailed(requestData.command, QStringLiteral("GM response has no success status"), requestData.background);
            reply->deleteLater();
            return;
        }

        emit connectionChanged(true);
        if (!response.value(QStringLiteral("value")).isObject()) {
            finishRequest(requestData, true, QStringLiteral("GM response has no object value"));
            emit commandFailed(requestData.command, QStringLiteral("GM response has no object value"), requestData.background);
        } else {
            finishRequest(requestData, false);
            emit commandSucceeded(requestData.command,
                                  response.value(QStringLiteral("value")).toObject(),
                                  requestData.background);
        }
        reply->deleteLater();
    });
}

void HadesToolsClient::finishRequest(const Request &request, bool clearPending, const QString &reason)
{
    const bool wasBusy = m_foregroundPending > 0;
    if (!request.background && m_foregroundPending > 0) {
        --m_foregroundPending;
    }
    if (clearPending) {
        const auto cancelled = m_pending;
        m_pending.clear();
        for (const auto &pending : cancelled) {
            if (!pending.background && m_foregroundPending > 0) {
                --m_foregroundPending;
            }
            emit commandCancelled(pending.command, reason, pending.background);
        }
    }
    if (wasBusy && m_foregroundPending == 0) {
        emit busyChanged(false);
    }
}
