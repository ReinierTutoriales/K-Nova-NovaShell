// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "Router.h"
namespace nova {
class Preferences {
public:
    explicit Preferences(QString path = {});
    Reply read() const;
    Reply patch(const QJsonObject &payload);
    static QJsonObject defaults();
private:
    static bool valid(const QString &key, const QJsonValue &value);
    QString m_path;
    QJsonObject m_values;
};
}
