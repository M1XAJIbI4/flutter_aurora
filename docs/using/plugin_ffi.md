# Plugin FFI

Специализированный пакет Dart, содержащий API, написанный на Dart, с одной или несколькими реализациями для конкретной платформы, использующими [Dart FFI](https://dart.dev/guides/libraries/c-interop).

!!! info

    Для демонстрации создания платформо-зависимого пакета для ОС Аврора типа был написан и опубликован проект
    [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages) в котором имеется приложение "Hello, World!".
    Полную статью с описанием проекта можно найти на Хабр - [Flutter на ОС Аврора](https://habr.com/ru/articles/761176/).

Проект "[Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages)" содержит в себе пакет реализующий платформо-зависимый плагин для ОС Аврора типа "Plugin FFI".
Данный пакет использует API ОС Аврора - [Device Info API](https://developer.auroraos.ru/doc/software_development/reference/device_info).
Плагин использует [QtDBus](https://doc.qt.io/qt-5/qtdbus-index.html), но не является плагином "Plugin Qt", так как не использует сигналы и слоты.

Создать пакет можно командой:

```shell
flutter-aurora create --template=plugin_ffi --platforms aurora <package-name>
```

Рассмотрим плагин "[ffi_plugin_device](https://gitlab.com/omprussia/flutter/demo-dart-packages/-/tree/master/packages/aurora/ffi_plugin_device?ref_type=heads)" из проекта [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages). **ffi_plugin_device** - платформо-зависимая реализация плагина "Flutter Device" для ОС Аврора.

Структура пакета **ffi_plugin_device**

```shell
└── aurora
    └── ffi_plugin_device
        ├── aurora
        │   └── CMakeLists.txt
        ├── ffigen.yaml
        ├── lib
        │   ├── ffi_plugin_device_bindings_generated.dart
        │   └── ffi_plugin_device.dart
        ├── pubspec.yaml
        └── src
            ├── CMakeLists.txt
            ├── ffi_plugin_device.cpp
            └── ffi_plugin_device.h
```

Для генерации привязок FFI можно использовать плагин [`ffigen`](https://pub.dev/packages/ffigen). 
Пакет, предоставляющий утилиты для работы с кодом интерфейса внешних функций, называется [`ffi`](https://pub.dev/packages/ffi). В `pubspec.yaml` плагина нужно добавить зависимости и активировать `ffiPlugin` для платформы ОС Аврора.

```yaml
dependencies:
  ffi: ^2.0.2

dev_dependencies:
  ffigen: ^7.2.7

flutter:
  plugin:
    platforms:
      aurora:
        ffiPlugin: true
        dartPluginClass: FFIPluginDevice
```

Для генерации привязок нужно добавить файл `ffigen.yaml` в корень плагина.

Файл `packages/aurora/ffi_plugin_device/ffigen.yaml`

```yaml
name: PluginDeviceBindings
llvm-path:
  - '/usr/lib/llvm-14/lib/libclang.so' # Ubuntu 22.04
  - '/usr/lib/llvm-15/lib/libclang.so' # Ubuntu 23.04
description: |
  Bindings for `src/ffi_plugin_device.h`.
output: 'lib/ffi_plugin_device_bindings_generated.dart'
headers:
  entry-points:
    - 'src/ffi_plugin_device.h'
  include-directives:
    - 'src/ffi_plugin_device.h'
comments:
  style: any
  length: full
```

В файле `ffigen.yaml` указываются хедеры нужных библиотек. В данном случае библиотека лежит в папке `src`, которая получает название модели устройства с помощью [`Qt D-Bus`](https://doc.qt.io/qt-5/qtdbus-index.html).

Файл `packages/aurora/ffi_plugin_device/src/ffi_plugin_device.h`

```cpp
#ifdef __cplusplus
extern "C" {
#endif

char *getDeviceName();

#ifdef __cplusplus
}
#endif
```

Файл `packages/aurora/ffi_plugin_device/src/ffi_plugin_device.cpp`

```cpp
#include <QStandardPaths>
#include <QtDBus/QtDBus>

#include "ffi_plugin_device.h"

char *getDeviceName()
{
    QString deviceName = "";
    if (QDBusConnection::sessionBus().isConnected()) {
        QDBusInterface iface("ru.omp.deviceinfo",
            "/ru/omp/deviceinfo/Features",
            "",
            QDBusConnection::sessionBus()
        );
        if (iface.isValid()) {
            QDBusReply<QString> reply = iface.call("getDeviceModel");
            if (reply.isValid()) {
                deviceName = reply.value();
            }
        }
    }
    return deviceName.toUtf8().data();
}
```

Выполнить генерацию FFI-привязок можно следующей командой, выполнив её из корня плагина (например, `packages/aurora/ffi_plugin_device`):

```shell
flutter-aurora pub run ffigen --config ffigen.yaml
```

В папке `lib` будет сгенерирован файл `ffi_plugin_device_bindings_generated.dart`.

Файл `packages/aurora/ffi_plugin_device/lib/ffi_plugin_device_bindings_generated.dart`

```dart
import 'dart:ffi' as ffi;

/// Bindings for `src/ffi_plugin_device.h`.
class PluginDeviceBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  PluginDeviceBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  PluginDeviceBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  ffi.Pointer<ffi.Char> getDeviceName() {
    return _getDeviceName();
  }

  late final _getDeviceNamePtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'getDeviceName');
  late final _getDeviceName =
      _getDeviceNamePtr.asFunction<ffi.Pointer<ffi.Char> Function()>();
}
```

Теперь можно создать класс `FFIPluginDevice`, реализующий интерфейс **[device_platform_interface](https://gitlab.com/omprussia/flutter/demo-dart-packages/-/tree/master/device_platform_interface?ref_type=heads)**.

Файл `packages/aurora/ffi_plugin_device/lib/ffi_plugin_device.dart`

```dart
class FFIPluginDevice extends DevicePlatform {
  /// Метод, который выполнится при старте приложения
  /// В этом методе можно установить платформо-зависимый плагин
  static void registerWith() {
    DevicePlatform.instance = FFIPluginDevice();
  }

  /// Привязки к нативным функциям в [_dylib].
  final PluginDeviceBindings _bindings = PluginDeviceBindings(
    DynamicLibrary.open('libffi_plugin_device.so'),
  );

  /// Реализация метода интерфейса [DevicePlatform]
  @override
  Future<String?> get deviceName async {
    // Получение deviceName
    final deviceName = _bindings.getDeviceName().cast<Utf8>().toDartString();
    // Возврат результата
    return deviceName == '' ? null : deviceName;
  }
}
```
