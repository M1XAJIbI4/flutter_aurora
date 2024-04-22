# Реализации плагина с использованием Qt

Пример платформо-зависимого плагина взаимодействующий с операционной системой Аврора через
[Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
с использованием [Signals & Slots](https://doc.qt.io/qt-5/signalsandslots.html) Qt.

> Задача плагина: Наблюдать за состоянием сетевого подключения с использованием Signals Qt.

![picture](../assets/images/examples/platform_channels_qt_demo_preview.png)

!!! note ""

    Этот демонстрационный плагин доступен в репозитории
    ["Flutter Plugins"](https://gitlab.com/omprussia/flutter/flutter-plugins)
    в разделе
    [demo/platform_channels_qt_demo](https://gitlab.com/omprussia/flutter/flutter-plugins/-/tree/main/demo/platform_channels_qt_demo).

### 1. Создаем проект

Плагин с поддержкой [Qt](https://doc.qt.io/) создается как
плагин [Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels),
который является платформо-зависимым, то есть зависит от операционной системы.
Подробнее про типы плагинов можно ознакомится в разделе ["Типы плагинов"](../structure/plugins.md#_1).
Platform Channels позволяет реализовать плагин обменивающийся данными через `MethodChannel` или `EventChannel`
с платформо-зависимой частью плагина из Dart части плагина.
Platform Channels так же дает доступ к публичным методам Flutter Embedder.

Как показано в [примере плагина FFI](./ffi.md) Qt могут работать без каких-либо дополнений.
Но для работы `Signals & Slots` требуются доработки которые продемонстрируем в этом разделе.

Для генерации шаблона плагина можно выполнить следующую команду в терминале:

```shell
flutter-aurora create --template=plugin --platforms aurora --org=ru.aurora platform_channels_qt_demo
```

- `ru.aurora` - Имя организации ([Organization name](https://doc.qt.io/qt-5/qcoreapplication.html#organizationName-prop)),
  участвует в формировании названия пакета.
- `platform_channels_qt_demo` название плагина ([Application Name](https://doc.qt.io/qt-5/qcoreapplication.html#applicationName-prop)), участвует в
  формировании названия пакета.

Данная команда генерирует базовый пример плагина Flutter с настроенным окружением для сборки под ОС Аврора.
Структура файлов и каталогов проекта имеет следующий вид:

```shell
.
├── analysis_options.yaml
├── aurora
│   ├── CMakeLists.txt
│   ├── include
│   │   └── platform_channels_qt_demo
│   │       ├── globals.h
│   │       └── platform_channels_qt_demo_plugin.h
│   └── platform_channels_qt_demo_plugin.cpp
├── CHANGELOG.md
├── example
│   ├── analysis_options.yaml
│   ├── aurora
│   │   ├── CMakeLists.txt
│   │   ├── desktop
│   │   │   └── ru.aurora.platform_channels_qt_demo_example.desktop
│   │   ├── icons
│   │   │   ├── 108x108.png
│   │   │   ├── 128x128.png
│   │   │   ├── 172x172.png
│   │   │   └── 86x86.png
│   │   ├── main.cpp
│   │   └── rpm
│   │       └── ru.aurora.platform_channels_qt_demo_example.spec
│   ├── integration_test
│   │   └── plugin_integration_test.dart
│   ├── lib
│   │   └── main.dart
│   ├── platform_channels_qt_demo_example.iml
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   ├── README.md
│   └── test
│       └── widget_test.dart
├── lib
│   ├── platform_channels_qt_demo.dart
│   ├── platform_channels_qt_demo_method_channel.dart
│   └── platform_channels_qt_demo_platform_interface.dart
├── LICENSE
├── platform_channels_qt_demo.iml
├── pubspec.lock
├── pubspec.yaml
├── README.md
└── test
    ├── platform_channels_qt_demo_method_channel_test.dart
    └── platform_channels_qt_demo_test.dart

14 directories, 32 files
```

Структура проекта, для разработчика Flutter, должна быть знакома.
Исключением является директория `<project>/aurora` в котором находится С++ код плагина
для взаимодействия с [Flutter Embedder](../structure/platform.md#flutter-embedder)
и реализации общения с кодом плагина на Dart через Platform Channels:

- `CMakeLists.txt` - сборка плагина реализована через [CMake](https://cmake.org/).
- `globals.h` - содержит определение `PLUGIN_EXPORT`.
- `platform_channels_demo_plugin.h` - хедер реализации плагина.
- `platform_channels_demo_plugin.cpp` - реализация плагина.

А в директории `<project>/example/aurora` находится файлы обеспечивающие работу демо-приложения плагина на платформе ОС Аврора:

- `CMakeLists.txt` - приложение и плагины Flutter для ОС Аврора имеет платформенную часть на С++, а сборка реализована
  через [CMake](https://cmake.org/).
- `desktop/ru.aurora.app_demo.desktop` - файл интеграции приложения в меню. В нем можно указать название приложения,
  требуемые права для приложения и некоторые другие настройки.
- `icons/*.png` - иконки приложения.
- `main.cpp` - тока входа в приложение для ОС Аврора. Это зачастую шаблонный код для запуска всех необходимых компонентов Flutter и
  приложения.
- `rpm/ru.aurora.app_demo.spec` - файл SPEC можно рассматривать как «рецепт», который утилита rpmbuild использует для фактической сборки
  RPM.

!!! note ""

    Если вы еще не знакомы с Flutter, с ним можно ознакомится на странице
    [документации Flutter](https://docs.flutter.dev/)
    и создать свое первое приложение [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab).

### 2. Доработка С++ части

В примере [плагина на Platform Channels](./platform-channels.md) была продемонстрирована передача данных и использования
`MethodChannel`. В этом плагине будет продемонстрирована работа с `EventChannel` на который можно будет подписаться
из кода Dart и слушать события отправляемые из С++ части плагина.
События будут приходить из сигналов Qt о состоянии сетевого подключения.

Для начала в `CMakeLists.txt` плагина, находящегося по пути: `<plugin>/aurora/CMakeLists.txt`,
добавим зависимости необходимые для получения информации о статусе сетевого подключения.

```cmake
cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME platform_channels_qt_demo)
set(PLUGIN_NAME  platform_channels_qt_demo_platform_plugin)

project(${PROJECT_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_CXX_FLAGS "-Wall -Wextra -Wno-psabi")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

find_package(PkgConfig REQUIRED)
# Добавить зависимости Qt
find_package(Qt5 COMPONENTS Core Network REQUIRED)
pkg_check_modules(FlutterEmbedder REQUIRED IMPORTED_TARGET flutter-embedder)

add_library(${PLUGIN_NAME} SHARED platform_channels_qt_demo_plugin.cpp)

# Активировать AUTOMOC
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden AUTOMOC ON)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::FlutterEmbedder)
# Добавить зависимости Qt
target_link_libraries(${PLUGIN_NAME} PUBLIC  Qt5::Core Qt5::Network)
target_include_directories(${PLUGIN_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
# Для поддержки Qt нужно добавить в include moc
target_include_directories(${PLUGIN_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_NAME})
target_compile_definitions(${PLUGIN_NAME} PRIVATE PLUGIN_IMPL)
```

В основном это шаблонный код генерируемый Flutter CLI, обратите **внимание** на прокомментированные строки
в файле `CMakeLists.txt` которые необходимо добавить для поддержки сигналов и слотов Qt.

Далее подправим хедер С++ части плагина находящийся по пути
`<plugin>/aurora/include/platform_channels_qt_demo/platform_channels_qt_demo_plugin.h`:

```C++
#ifndef FLUTTER_PLUGIN_PLATFORM_CHANNELS_QT_DEMO_PLUGIN_H
#define FLUTTER_PLUGIN_PLATFORM_CHANNELS_QT_DEMO_PLUGIN_H

#include <platform_channels_qt_demo/globals.h>

// Добавить зависимость Qt
#include <QNetworkConfigurationManager>

#include <flutter/plugin_registrar.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>

// Flutter encodable
typedef flutter::EncodableValue EncodableValue;
typedef flutter::EncodableMap EncodableMap;
typedef flutter::EncodableList EncodableList;
// Flutter события
typedef flutter::EventChannel<EncodableValue> EventChannel;
typedef flutter::EventSink<EncodableValue> EventSink;

// Включить QObject
class PLUGIN_EXPORT PlatformChannelsQtDemoPlugin final
    : public QObject
    , public flutter::Plugin
{
    Q_OBJECT
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar);

// Создать слот
public slots:
    void onEventChannelSend();

private:
    // Создает плагин, который взаимодействует по данному каналу.
    PlatformChannelsQtDemoPlugin(
        std::unique_ptr<EventChannel> eventChannel
    );

    // Метод регистрируют обработчики каналов
    void RegisterStreamHandler();

    // Другие методы
    void onEventChannelEnable();
    void onEventChannelDisable();

    // Переменные Flutter
    std::unique_ptr<EventChannel> m_eventChannel;
    std::unique_ptr<EventSink> m_sink;

    // Переменные Qt
    bool m_state;
    QNetworkConfigurationManager m_manager;
    QMetaObject::Connection m_onlineStateChangedConnection;
};

#endif /* FLUTTER_PLUGIN_PLATFORM_CHANNELS_QT_DEMO_PLUGIN_H */
```

Здесь заменяем `MethodChannel` созданный шаблоном на `EventChannel` который позволит реализовать `Stream` на стороне Dart.
Добавляем методы для реакции на подпись к `Stream` Dart.
Подключаем `QObject` к классу, добавляем необходимые методы для работы с событиями
и `Qt` классы которые позволят слушать сигналы об изменении состояния сети.

Можно перейти к реализации методов объявленных в хедере.
Откроем и модифицируем файл по пути `<plugin>/aurora/platform_channels_qt_demo_plugin.cpp`:

```c++
#include <platform_channels_qt_demo/platform_channels_qt_demo_plugin.h>

namespace Channels {
constexpr auto Event = "platform_channels_qt_demo";
} // namespace Channels

void PlatformChannelsQtDemoPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  // Создайте EventChannel с помощью StandardMethodCodec
  auto eventChannel = std::make_unique<EventChannel>(
      registrar->messenger(), Channels::Event,
      &flutter::StandardMethodCodec::GetInstance());

  // Создать плагин
  std::unique_ptr<PlatformChannelsQtDemoPlugin> plugin(
      new PlatformChannelsQtDemoPlugin(std::move(eventChannel)));

  // Зарегистрировать плагин
  registrar->AddPlugin(std::move(plugin));
}

PlatformChannelsQtDemoPlugin::PlatformChannelsQtDemoPlugin(
    std::unique_ptr<EventChannel> eventChannel)
    : m_eventChannel(std::move(eventChannel)) {
  // Создать StreamHandler
  RegisterStreamHandler();
}

void PlatformChannelsQtDemoPlugin::RegisterStreamHandler()
{
    // Создать обработчик событий Platform Channels
    auto handler = std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
        [&](const EncodableValue*,
            std::unique_ptr<flutter::EventSink<EncodableValue>>&& events
        ) -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            m_sink = std::move(events);
            onEventChannelEnable();
            return nullptr;
        },
        [&](const EncodableValue*) -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            onEventChannelDisable();
            return nullptr;
        }
    );

    // Зарегистрировать событие
    m_eventChannel->SetStreamHandler(std::move(handler));
}

void PlatformChannelsQtDemoPlugin::onEventChannelEnable()
{
    // Отправить после запуска
    onEventChannelSend();
    // Подключить соединение для прослушивания
    m_onlineStateChangedConnection =
        QObject::connect(&m_manager,
                         &QNetworkConfigurationManager::onlineStateChanged,
                         this,
                         &PlatformChannelsQtDemoPlugin::onEventChannelSend);
}

void PlatformChannelsQtDemoPlugin::onEventChannelDisable()
{
    // Отключить соединение для прослушивания
    QObject::disconnect(m_onlineStateChangedConnection);
}

void PlatformChannelsQtDemoPlugin::onEventChannelSend()
{
    // Отправить состояние если были изменения
    auto state = m_manager.isOnline();
    if (state != m_state) {
        m_state = state;
        m_sink->Success(m_manager.isOnline());
    }
}

// Добавить мок-файл
#include "moc_platform_channels_qt_demo_plugin.cpp"
```

Действия в коде подробно описаны.
Обратите **внимание** на конец файлы где добавлен мок файл `{moc}_{file_plugin_name.cpp}`:

```c++
#include "moc_platform_channels_qt_demo_plugin.cpp"
```

Он реализует автоматически необходимый функционал для работы `Qt` в плагине.

### 3. Доработка Dart части

После реализации платформо-зависимого кода С++ нужно модифицировать шаблонный код плагина для создания `Stream` в `Dart`.
Плагин Dart содержит 3 класса:

- `PlatformChannelsQtDemo` - сам плагин который подключается в приложение.
- `PlatformChannelsQtDemoPlatform` - интерфейс который позволяет расширять плагин.
- `MethodChannelPlatformChannelsQtDemo` - реализация методов интерфейса плагина.

В Dart части плагина нам нужно подправить все файлы для реализации для задачи плагина: получение состояния статуса сетевого подключения.
Для этого в файле `<plugin>/lib/platform_channels_qt_demo.dart` подправим класс `PlatformChannelsQtDemo`,
удалив шаблонный код и добавив метод со Stream который будет сообщать о смене состояния сетевого подключения:

```dart
class PlatformChannelsQtDemo {
  Stream<bool?> stateNetworkConnect() {
    return PlatformChannelsQtDemoPlatform.instance.stateNetworkConnect();
  }
}
```

В файле `<plugin>/lib/platform_channels_qt_demo_platform_interface.dart` обновим методы интерфейса:

```dart
/// ...
Stream<bool?> stateNetworkConnect() {
  throw UnimplementedError('connectNetworkState() has not been implemented.');
}
```

И в файле `<plugin>/lib/platform_channels_qt_demo_method_channel.dart` реализуем метод интерфейса:

```dart
import 'package:flutter/services.dart';
import 'platform_channels_qt_demo_platform_interface.dart';

// Ключ канала плагина
const channelEvent = "platform_channels_qt_demo";

/// Реализация [PlatformChannelsQtDemoPlatform], использующая каналы методов.
class MethodChannelPlatformChannelsQtDemo extends PlatformChannelsQtDemoPlatform {
  /// Канал метода, используемый для взаимодействия с собственной платформой.
  final eventChannel = const EventChannel(channelEvent);

  /// Отображение состояния сети с помощью EventChannel
  @override
  Stream<bool?> stateNetworkConnect() {
    return eventChannel.receiveBroadcastStream().map((event) => event as bool);
  }
}
```

### 4. Доработка примера

Шаблон Platform Channels плагина генерируемый Flutter CLI имеет приложение-пример работы с плагином в директории
`<project>/example`.
Доработаем его для отображения статуса сетевого подключения через плагин.

Так как плагин использует Qt-библиотеку [Qt Network](https://doc.qt.io/qt-5/qtnetwork-index.html)
ее следует добавить в зависимости приложения.
Для этого в файл `<project>/example/aurora/rpm/ru.aurora.platform_channels_qt_demo_example.spec` нужно добавить:

```spec
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Network)
```

Для получения статуса сетевого подключения приложению требуются права доступа `Internet`,
которые нужно добавить в файл `<project>/example/aurora/desktop/ru.aurora.platform_channels_qt_demo_example.desktop`

```desktop
Permissions=Internet
```

Активировать сигналы и слоты Qt можно подключив доступный функционал Flutter Embedder к приложению.
Откроем файл `<project>/example/aurora/main.cpp` и обновим его следующим образом:

```c++
#include <flutter/flutter_aurora.h>
#include <flutter/flutter_compatibility_qt.h> // <- Подключение Qt
#include "generated_plugin_registrant.h"

int main(int argc, char *argv[]) {
    aurora::Initialize(argc, argv);
    aurora::EnableQtCompatibility(); // <- Подключение Qt
    aurora::RegisterPlugins();
    aurora::Launch();
    return 0;
}
```

Для повышения читаемости кода, систематизации и упрощения написания приложений-примеров
был разработан плагин `internal_aurora`.
Более детально с ним можно ознакомится в разделе ["Пакет Internal"](../structure/plugins.md#internal).
Добавить в зависимость плагин `internal_aurora` можно следующим образом:

```yaml
dependencies:
  internal_aurora:
    git:
      url: https://gitlab.com/omprussia/flutter/flutter-plugins.git
      ref: internal_aurora-1.0.0
      path: packages/internal_aurora
```

Обновим зависимости в директории `example`:

```shell
cd example
flutter-aurora pub get
```

Доработаем приложение которые будет использовать плагин `platform_channels_qt_demo`
и демонстрировать статус сетевого подключения:

```dart
import 'package:flutter/material.dart';
import 'package:internal_aurora/list_item_data.dart';
import 'package:internal_aurora/list_item_info.dart';
import 'package:internal_aurora/list_separated.dart';
import 'package:internal_aurora/theme/colors.dart';
import 'package:internal_aurora/theme/theme.dart';
import 'package:platform_channels_qt_demo/platform_channels_qt_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PlatformChannelsQtDemo _plugin = PlatformChannelsQtDemo();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: internalTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Platform Channels Qt Demo'),
        ),
        body: ListSeparated(
          children: [
            const ListItemInfo("""
            An example of a platform-dependent plugin that works with the
            Aurora OS via the Platform Channels and Qt signal/slot.
            """),
            ListItemData(
              'State network connect',
              InternalColors.purple,
              description:
              'Listen status network connect through Platform Channels with use Qt',
              stream: _plugin.stateNetworkConnect(),
            ),
          ],
        ),
      ),
    );
  }
}
```

Теперь можно собрать приложение.
В корне проекта выполнить команду Flutter CLI для сборки приложения и получения установочного файла RPM.

```shell
flutter-aurora build aurora --target-platform aurora-x64 --release
```

!!! info

    В данном случае в команде на сборку указана архитектура `--target-platform aurora-x64` (`x86_64`)
    на которой работает эмулятор.
    Для сборки доступны и другие архитектуры, более детально с этим вопросом можно ознакомится в разделе
    ["Target platform"](../examples/build.md#1-target-platform).

После успешной сборки можно наблюдать следующий вывод в терминале:

```shell
┌─ Result ────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ./build/aurora/psdk_5.0.0.60/aurora-x64/release/RPMS/ru.aurora.platform_channels_qt_demo_example-0.1.0-1.x86_64.rpm │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

Этот путь указывает на установочный RPM пакет который можно
[подписать](../faq/index.md#rpm) и [установить](../faq/index.md#_6)
на эмулятор.

### 5. Плагин готов!

Реализация плагина с использованием Platform Channels дает максимальные возможности для реализации плагина,
а подключение Qt широкий выбор готовых компонентов работающий на операционной системе Аврора.
Но нужно учитывать что реализация такого плагина требует дополнительных ресурсов,
реализация плагина без использования Qt, все же, является плюсом в пользу производительности.

