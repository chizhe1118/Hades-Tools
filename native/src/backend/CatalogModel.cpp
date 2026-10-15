#include "CatalogModel.h"

CatalogModel::CatalogModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    m_source.setItemRoleNames({{KeyRole, "key"}, {NameRole, "name"},
                              {DescriptionRole, "description"}, {IconRole, "icon"},
                              {ChineseNameRole, "chineseName"}, {EnglishNameRole, "englishName"}});
    setSourceModel(&m_source);
    setFilterRole(Qt::DisplayRole);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    connect(this, &QAbstractItemModel::modelReset, this, &CatalogModel::countChanged);
    connect(this, &QAbstractItemModel::rowsInserted, this, &CatalogModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &CatalogModel::countChanged);
}

int CatalogModel::count() const
{
    return rowCount();
}

void CatalogModel::setFilterText(const QString &text)
{
    const auto query = text.trimmed();
    if (query == m_filterText) return;
    m_filterText = query;
    setFilterFixedString(query);
    emit filterTextChanged();
}

void CatalogModel::setRows(const QJsonArray &rows)
{
    m_source.removeRows(0, m_source.rowCount());
    for (const QJsonValue &value : rows) {
        if (value.isObject()) {
            const auto row = value.toObject();
            auto *item = new QStandardItem;
            const auto key = row.value(QStringLiteral("key")).toString();
            const auto name = row.value(QStringLiteral("name")).toString();
            const auto chineseName = displayName(key, QStringLiteral("zh"));
            const auto englishName = displayName(key, QStringLiteral("en"));
            item->setData(key + QLatin1Char(' ') + name + QLatin1Char(' ')
                          + chineseName + QLatin1Char(' ') + englishName, Qt::DisplayRole);
            item->setData(key, KeyRole);
            item->setData(name, NameRole);
            item->setData(chineseName, ChineseNameRole);
            item->setData(englishName, EnglishNameRole);
            item->setData(row.value(QStringLiteral("description")).toString(), DescriptionRole);
            item->setData(row.value(QStringLiteral("icon")).toString(), IconRole);
            m_source.appendRow(item);
        }
    }
    emit countChanged();
}

void CatalogModel::setTranslations(const QJsonObject &translations)
{
    m_translations = translations;
}

QString CatalogModel::displayName(const QString &key, const QString &language) const
{
    const auto entry = m_translations.value(key).toObject();
    const auto text = entry.value(language == QStringLiteral("zh") ? QStringLiteral("zh")
                                                                : QStringLiteral("en")).toString();
    // Unknown keys remain visible so catalog changes can be identified and translated.
    return text.isEmpty() ? key : text;
}
