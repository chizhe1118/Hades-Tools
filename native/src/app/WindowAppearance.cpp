#include "WindowAppearance.h"

#include <QQuickWindow>
#include <QEvent>
#include <QDebug>
#ifdef Q_OS_WIN
#include <qt_windows.h>
#include <dwmapi.h>
#endif

WindowAppearance::WindowAppearance(QQuickWindow *window)
    : QObject(window), m_window(window)
{
    m_window->installEventFilter(this);
    apply();
}

void WindowAppearance::setDark(bool dark)
{
    m_dark = dark;
    apply();
}

bool WindowAppearance::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_window && (event->type() == QEvent::Show
        || event->type() == QEvent::WinIdChange || event->type() == QEvent::WindowStateChange)) apply();
    return QObject::eventFilter(watched, event);
}

void WindowAppearance::apply()
{
#ifdef Q_OS_WIN
    const auto handle = reinterpret_cast<HWND>(m_window->winId());
    // Windows 11 DWM attributes; numeric IDs also compile with older MinGW headers.
    constexpr DWORD cornerPreferenceAttribute = 33; // DWMWA_WINDOW_CORNER_PREFERENCE
    constexpr DWORD immersiveDarkModeAttribute = 20; // DWMWA_USE_IMMERSIVE_DARK_MODE
    const int cornerPreference = m_window->visibility() == QWindow::Maximized ? 1 : 2; // DONOTROUND / ROUND
    const BOOL dark = m_dark ? TRUE : FALSE;
    const auto corners = DwmSetWindowAttribute(handle, cornerPreferenceAttribute,
                                              &cornerPreference, sizeof(cornerPreference));
    const auto appearance = DwmSetWindowAttribute(handle, immersiveDarkModeAttribute, &dark, sizeof(dark));
    if (FAILED(corners)) qWarning() << "DWM corner preference failed:" << Qt::hex << quint32(corners);
    if (FAILED(appearance)) qWarning() << "DWM appearance failed:" << Qt::hex << quint32(appearance);
#endif
}
