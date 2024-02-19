# Plugin D-Bus

Пакеты, написанные на Dart, - например, package [`path`](https://pub.dev/packages/path). Они могут содержать специфичные для Flutter функции и иметь зависимость от инфраструктуры Flutter, ограничивая их использование только Flutter, например, package [`fluro`](https://pub.dev/packages/fluro).

!!! info

    Для демонстрации создания платформо-зависимого пакета для ОС Аврора типа был написан и опубликован проект
    [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages), в котором имеется приложение "Hello, World!".
    Полную статью с описанием проекта можно найти на Хабр - [Flutter на ОС Аврора](https://habr.com/ru/articles/761176/).

Проект "[Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages)" содержит в себе пакет, реализующий платформо-зависимый пакет для ОС Аврора типа "Plugin D-Bus".
Пакет "[Flutter Device](https://gitlab.com/omprussia/flutter/demo-dart-packages/-/tree/master/packages/aurora/dart_package_device?ref_type=heads)" из проекта [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages) становится платформо-зависимым, используя [D-Bus](https://www.freedesktop.org/wiki/Software/dbus/) ОС Аврора.
Данный пакет использует - "[Device Info API](https://developer.auroraos.ru/doc/software_development/reference/device_info)".

Пакет Dart в минимальном виде состоит из файла [`pubspec.yaml`](https://dart.dev/tools/pub/pubspec), папки `lib` с как минимум одним файлом `<package-name>.dart`. 
Создать пакет можно командой:

```shell
flutter-aurora create --template=package <package-name>
```

Рассмотрим пакет "[dart_package_device](https://gitlab.com/omprussia/flutter/demo-dart-packages/-/tree/master/packages/aurora/dart_package_device?ref_type=heads)" из проекта [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages). **dart_package_device** - платформо-зависимая реализация плагина "Flutter Device" для ОС Аврора. 
В основе пакета лежит пакет `dbus` - нативная клиентская реализация D-Bus для Dart. С его помощью можно реализовать пакет Dart для ОС Аврора, ни строчки не написав на C++.

Структура пакета **dart_package_device**:

```shell
└── aurora
    └── dart_package_device
        ├── lib
        │   ├── dart_package_device.dart
        │   └── ru_omp_device_info_features.dart
        ├── ru.omp.deviceinfo.Features.xml
        └── pubspec.yaml
```

Пакет `dbus` позволяет на основе xml-файла с интерфейсом D-Bus генерировать Dart-класс, который позволит выполнить доступные методы.

Файл `packages/aurora/dart_package_device/ru.omp.deviceinfo.Features.xml`

```xml
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
        "http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node>
    <interface name="ru.omp.deviceinfo.Features">
        <method name="getDeviceModel">
            <arg type="s" direction="out"/>
        </method>
    </interface>
</node>
```

Выполнить генерацию можно командой:

```shell
dart-dbus generate-remote-object ./ru.omp.deviceinfo.Features.xml \
-o lib/ru_omp_device_info_features.dart
```

Результат генерации c файла `ru.omp.deviceinfo.Features.xml` следует рассматривать как отправную точку для реализации.

Файл `packages/aurora/dart_package_device/lib/ru_omp_device_info_features.dart`

```dart
class RuOmpDeviceinfoFeatures extends DBusRemoteObject {
  RuOmpDeviceinfoFeatures(
      DBusClient client, String destination, DBusObjectPath path)
      : super(client, name: destination, path: path);

  /// Вызов ru.omp.deviceinfo.Features.getDeviceModel()
  Future<String> callGetDeviceModel(
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod(
        'ru.omp.deviceinfo.Features', 'getDeviceModel', [],
        replySignature: DBusSignature('s'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asString();
  }
}
```

Теперь можно реализовать интерфейс **[device_platform_interface](https://gitlab.com/omprussia/flutter/demo-dart-packages/-/tree/master/device_platform_interface?ref_type=heads)** и в методе `registerWith` указать пакет **dart_package_device** как платформо-зависимый плагин.

Файл `packages/aurora/dart_package_device/lib/dart_package_device.dart`

```dart
/// Метод, который выполнится при старте приложения
/// В этом методе можно установить платформо-зависимый плагин
static void registerWith() {
  DevicePlatform.instance = DartPackageDevice();
}

/// Реализация метода интерфейса [DevicePlatform]
@override
Future<String?> get deviceName async {
  // Инициализация клиента D-Bus
  final client = DBusClient.session();

  // Инициализация объекта
  final features = RuOmpDeviceinfoFeatures(
    client,
    'ru.omp.deviceinfo',
    DBusObjectPath('/ru/omp/deviceinfo/Features'),
  );

  // Выполнение метода
  final deviceName = await features.callGetDeviceModel();

  // Закрытие клиента D-Bus
  await client.close();

  // Возвращение результата
  return deviceName == '' ? null : deviceName;
}
```

В `pubspec.yaml` плагина **dart_package_device** следует указать `dartPluginClass` для того, чтобы с помощью метода `registerWith` прошла регистрация плагина в `общем-плагине` **flutter_device** при старте приложения.

```yaml
flutter:
  plugin:
    platforms:
      aurora:
        dartPluginClass: DartPackageDevice
```
