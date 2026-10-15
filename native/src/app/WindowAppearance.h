#pragma once

#include <QObject>

class QQuickWindow;

class WindowAppearance final : public QObject
{
public:
    explicit WindowAppearance(QQuickWindow *window);
    void setDark(bool dark);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    void apply();
    QQuickWindow *m_window;
    bool m_dark{false};
};
