#pragma once

#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QJsonArray>
#include <QJsonObject>

class CatalogModel final : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)

public:
    enum Roles { KeyRole = Qt::UserRole + 1, NameRole, DescriptionRole, IconRole, ChineseNameRole, EnglishNameRole };
    Q_ENUM(Roles)

    explicit CatalogModel(QObject *parent = nullptr);

    int count() const;
    QString filterText() const { return m_filterText; }
    void setFilterText(const QString &text);
    void setRows(const QJsonArray &rows);
    void setTranslations(const QJsonObject &translations);
    Q_INVOKABLE QString displayName(const QString &key, const QString &language) const;

signals:
    void countChanged();
    void filterTextChanged();

private:
    QStandardItemModel m_source;
    QString m_filterText;
    QJsonObject m_translations;
};
