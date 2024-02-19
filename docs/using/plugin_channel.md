# Plugin Channel

Специализированный пакет Dart, содержащий API, написанный на Dart, в сочетании с одной или несколькими реализациями для конкретной платформы. Пакеты плагинов могут быть написаны для Android (с использованием Kotlin или Java), ОС Аврора (с использование С++), iOS (с использованием Swift или Objective-C), Интернета, macOS, Windows или Linux или любой их комбинации.

!!! info

    Для демонстрации создания платформо-зависимого пакета для ОС Аврора типа был написан и опубликован проект
    [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages), в котором имеется приложение "Hello, World!".
    Полную статью с описанием проекта можно найти на Хабр - [Flutter на ОС Аврора](https://habr.com/ru/articles/761176/).

Проект [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages) содержит в себе пакет, реализующий платформо-зависимый плагин для ОС Аврора типа "Plugin Channel". 
Данный пакет использует API ОС Аврора - [Device Info API](https://developer.auroraos.ru/doc/software_development/reference/device_info). 
Плагин использует [QtDBus](https://doc.qt.io/qt-5/qtdbus-index.html), но не является плагином "Plugin Qt", так как не использует сигналы и слоты.

Создать пакет можно следующей командой:

```shell
flutter-aurora create --template=plugin --platforms aurora <package-name>
```

Рассмотрим плагин "[plugin_device](https://gitlab.com/omprussia/flutter/demo-dart-packages/-/tree/master/packages/aurora/plugin_device?ref_type=heads)" из проекта [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages). **plugin_device** - платформо-зависимая реализация плагина "Flutter Device" для ОС Аврора типа "Plugin package".

Структура пакета **plugin_device**:

```shell
└── aurora
    └── plugin_device
        ├── aurora
        │   ├── CMakeLists.txt
        │   ├── include
        │   │   └── plugin_device
        │   │       └── plugin_device_plugin.h
        │   └── plugin_device_plugin.cpp
        ├── lib
        │   ├── plugin_device.dart
        │   └── plugin_device_method_channel.dart
        └── pubspec.yaml
```

В `pubspec.yaml` плагина **plugin_device** нужно указать `pluginClass` и `dartPluginClass`.

```yaml
flutter:
  plugin:
    platforms:
      aurora:
        pluginClass: PluginDevicePlugin
        dartPluginClass: PluginDevice
```

`PluginDevicePlugin` - C++ класс, реализующий `PluginInterface` пакета `flutter-embedder`.

Файл `packages/aurora/plugin_device/aurora/include/plugin_device/plugin_device_plugin.h`

```cpp
#include <flutter/plugin-interface.h>
#include <plugin_device/globals.h>

class PLUGIN_EXPORT PluginDevicePlugin final : public PluginInterface
{
public:
    void RegisterWithRegistrar(PluginRegistrar &registrar) override;

private:
    void onMethodCall(const MethodCall &call);
    void onGetDeviceName(const MethodCall &call);
    void unimplemented(const MethodCall &call);
};
```

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
```

`PluginDevice` - Dart-класс, реализующий **[device_platform_interface](https://gitlab.com/omprussia/flutter/demo-dart-packages/-/tree/master/device_platform_interface?ref_type=heads)** и устанавливающий при выполнении метода `registerWith` нужный экземпляр для взаимодействия с платформо-зависимой частью плагина.

Файл `packages/aurora/plugin_device/lib/plugin_device.dart`

```dart
class PluginDevice extends DevicePlatform {
  /// Метод, который выполнится при старте приложения
  /// В этом методе можно установить платформо-зависимый плагин
  static void registerWith() {
    DevicePlatform.instance = MethodChannelPluginDevice();
  }

  /// Реализация метода интерфейса [DevicePlatform]
  @override
  Future<String?> get deviceName => DevicePlatform.instance.deviceName;
}
```

[MethodChannel](https://api.flutter.dev/flutter/services/MethodChannel-class.html) - класс плагина, отличается от подобного класса для Android только названием и ключом для взаимодействия с платформо-зависимой частью.

Файл `packages/aurora/plugin_device/lib/plugin_device_method_channel.dart`

```dart
/// Реализация [PluginDevicePlatform], которая использует каналы методов
class MethodChannelPluginDevice extends DevicePlatform {
  /// Канал метода, используемый для взаимодействия с собственной платформой
  @visibleForTesting
  final methodChannel = const MethodChannel('plugin_device');

  /// Реализация метода получения названия устройства
  /// getDeviceName - название метода, который можно проверить
  /// в платформо-зависимой части плагина
  @override
  Future<String?> get deviceName async {
    return await methodChannel.invokeMethod<String>('getDeviceName');
  }
}
```
