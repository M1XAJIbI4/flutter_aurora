# Plugin Qt

Qt plugin package - является обычным плагином типа "[Plugin Channel](plugin_channel.md)", но использующего Qt сигналы и слоты. 
Проект [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages) содержит в себе пакет, реализующий платформо-зависимый плагин для ОС Аврора типа "Plugin package", на его примере покажем, как подключить сигналы и слоты к плагину.

Плагин уже имеет в зависимостях Qt, но в нем не будут работать сигналы и слоты. Для их подключения следует добавить зависимости в класс, реализующий `PluginInterface`:

Файл `packages/aurora/plugin_device/aurora/include/plugin_device/plugin_device_plugin.h`

```cpp
#include <flutter/plugin-interface.h>
#include <plugin_device/globals.h>

#include <QtCore>

class PLUGIN_EXPORT PluginDevicePlugin final
    : public QObject
    , public PluginInterface
{
    Q_OBJECT

public:
    void RegisterWithRegistrar(PluginRegistrar &registrar) override;

private:
    void onMethodCall(const MethodCall &call);
    void onGetDeviceName(const MethodCall &call);
    void unimplemented(const MethodCall &call);
};
```

А в файл реализации добавить в низ файла `#include "moc_sensors_plus_aurora_plugin.cpp"`:

Файл `packages/aurora/plugin_device/aurora/plugin_device_plugin.cpp`

```cpp
#include <plugin_device/plugin_device_plugin.h>
#include <flutter/method-channel.h>
#include <QtDBus/QtDBus>

/**
 * Регистрация [MethodChannel].
 */
void PluginDevicePlugin::RegisterWithRegistrar(PluginRegistrar &registrar)
{
    registrar.RegisterMethodChannel("plugin_device",
                                    MethodCodecType::Standard,
                                    [this](const MethodCall &call) { this->onMethodCall(call); });
}

/**
 * Метод onMethodCall будет выполняться при вызове MethodChannel из Dart-плагина.
 * По названию, передаваемому из плагина, можно вызвать нужный платформо-зависимый метод.
 */
void PluginDevicePlugin::onMethodCall(const MethodCall &call)
{
    const auto &method = call.GetMethod();
    if (method == "getDeviceName") {
        onGetDeviceName(call);
        return;
    }
    unimplemented(call);
}

/**
 * Платформо-зависимый метод, получающий название устройства
 */
void PluginDevicePlugin::onGetDeviceName(const MethodCall &call)
{
    if (!QDBusConnection::sessionBus().isConnected()) {
        call.SendSuccessResponse(nullptr);
        return;
    }
    QDBusInterface iface("ru.omp.deviceinfo",
        "/ru/omp/deviceinfo/Features",
        "",
        QDBusConnection::sessionBus()
    );
    if (iface.isValid()) {
        QDBusReply<QString> reply = iface.call("getDeviceModel");
        if (reply.isValid()) {
            call.SendSuccessResponse(reply.value().toStdString());
            return;
        }
    }
    call.SendSuccessResponse(nullptr);
}

/**
 * Метод, возвращающий [nullptr], если запрашиваемый метод не найден
 */
void PluginDevicePlugin::unimplemented(const MethodCall &call)
{
    call.SendSuccessResponse(nullptr);
}

#include "moc_sensors_plus_aurora_plugin.cpp"
```

Для того чтобы произошла генерация мок-файла, добавим в [set_target_properties](https://cmake.org/cmake/help/latest/command/set_target_properties.html) `AUTOMOC ON`:

Файл `packages/aurora/plugin_device/aurora/CMakeLists.txt`

```
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden AUTOMOC ON)
```

Для подключения Qt в плагин, нужно добавить в `CMakeLists.txt` как минимум [QtCore](https://doc.qt.io/qt-5/qtcore-index.html):

```
find_package(Qt5 COMPONENTS Core REQUIRED)

target_link_libraries(${PLUGIN_NAME} PUBLIC Qt5::Core)
```

Для работы плагина в приложении Qt нужно включить отдельно. Сделать это можно, добавив в `main` функцию приложения вызов метода `EnableQtCompatibility()`.
Выглядеть это может следующим образом:

```cpp
#include <flutter/application.h>
#include <flutter/compatibility.h>
#include "generated_plugin_registrant.h"

int main(int argc, char *argv[]) {
    Application::Initialize(argc, argv);
    EnableQtCompatibility(); // Включение "Qt plugin package" плагинов
    RegisterPlugins();
    Application::Launch();
    return 0;
}
```

После добавления зависимостей в плагин начнут работать сигналы и слоты Qt.
ОС Аврора очень зависит от Qt, во Flutter мы стараемся минимизировать эту зависимость.
Если есть возможность выбора типа для реализации платформо-зависимого плагина, использование Qt нежелательно, но приемлемо в отсутствии альтернатив.
