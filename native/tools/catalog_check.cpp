#include "CatalogModel.h"
#include <QCoreApplication>
#include <QFile>
#include <QJsonDocument>
#include <QDebug>

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    if (app.arguments().size() != 3) return 2;
    QFile names(app.arguments()[1]);
    QFile snapshot(app.arguments()[2]);
    if (!names.open(QIODevice::ReadOnly) || !snapshot.open(QIODevice::ReadOnly)) return 3;
    const auto categories = QJsonDocument::fromJson(names.readAll()).object().value("categories").toObject();
    const auto catalog = QJsonDocument::fromJson(snapshot.readAll()).object();
    int total = 0;
    for (const auto &category : {"resources", "consumables", "traits", "loot", "weapons"}) {
        CatalogModel model;
        model.setTranslations(categories.value(category).toObject());
        QJsonArray rows;
        for (const auto &value : catalog.value(category).toArray()) {
            if (QString::fromLatin1(category) != "weapons" || value.toObject().value("heroWeapon").toBool()) rows.append(value);
        }
        model.setRows(rows);
        const auto count = rows.size();
        if (model.count() != count) return 4;
        for (const auto &value : rows) {
            const auto key = value.toObject().value("key").toString();
            for (const auto &query : {key.toLower(), model.displayName(key, "en"), model.displayName(key, "zh")}) {
                model.setFilterText("  " + query + "  ");
                bool found = false;
                for (int i = 0; i < model.count(); ++i) {
                    if (model.data(model.index(i, 0), CatalogModel::KeyRole).toString() == key) found = true;
                }
                if (!found) { qCritical() << category << key << query; return 5; }
            }
        }
        model.setFilterText("[.*]+?no_such_catalog_entry");
        if (model.count() != 0) return 6;
        model.setFilterText("");
        if (model.count() != count) return 7;
        qInfo() << category << count << "entries searched by Chinese, English and raw key";
        total += count;
    }
    qInfo() << "Passed:" << total << "entries; literal search, clear and trim";
    return 0;
}
