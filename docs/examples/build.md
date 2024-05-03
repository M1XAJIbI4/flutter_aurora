# Приложение на Flutter для ОС Аврора

### Добро пожаловать!

Вы уже [установили](../install/linux.md) Flutter с поддержкой ОС Аврора и желаете собрать свое приложение либо создать новое?
Вы попали в нужный раздел.
В этом разделе будет показано как добавить поддержку ОС Аврора к уже существующим приложениям,
как создать новое приложение,
либо написать платформо-зависимый плагин для ОС Аврора разными вариантами
([Плагин D-Bus](./dbus.md), [Плагин FFI](./ffi.md), [Плагин Platform](./platform-channels.md), [Плагин Platform & Qt](./platform-channels-qt.md)).

### 1. Создаем проект

Flutter SDK имеет интерфейс командной строки ([Flutter CLI](https://docs.flutter.dev/reference/flutter-cli)),
дающий доступ к инструментам Flutter.
С помощью `Flutter CLI` можно создать приложение из шаблонов доступных во Flutter SDK, собрать приложение и многое другое.
Со статусом доступности команд для платформы ОС Аврора можно ознакомится в разделе ["Flutter CLI"](../support/cli.md).

Создать приложение из шаблона можно следующей командой:

```shell
flutter-aurora create --platforms=aurora --template=app --org=ru.aurora app_demo
```

Давайте разберем команду:

- `flutter-aurora` - `alias` добавленный при [установке](../install/linux.md).
- `create` - команда для создания приложений/плагинов из шаблонов.
- `--platforms=aurora` - указываем для какой платформы создавать шаблон.
- `--template=app` - указываем тип шаблона (`app`,`package`,`plugin_ffi`,`plugin`).
- `--org=ru.aurora` - имя организации ([Organization name](https://doc.qt.io/qt-5/qcoreapplication.html#organizationName-prop)), участвует в
  формировании названия пакета.
- `app_demo` - название приложения ([Application Name](https://doc.qt.io/qt-5/qcoreapplication.html#applicationName-prop)), участвует в
  формировании названия пакета.

После выполнения команды будет создан проект из шаблона Flutter SDK, имеющий структуру следующего вида:

```shell
.
├── analysis_options.yaml
├── app_demo.iml
├── aurora
│   ├── CMakeLists.txt
│   ├── desktop
│   │   └── ru.aurora.app_demo.desktop
│   ├── icons
│   │   ├── 108x108.png
│   │   ├── 128x128.png
│   │   ├── 172x172.png
│   │   └── 86x86.png
│   ├── main.cpp
│   └── rpm
│       └── ru.aurora.app_demo.spec
├── lib
│   └── main.dart
├── pubspec.lock
├── pubspec.yaml
├── README.md
└── test
    └── widget_test.dart

7 directories, 15 files
```

Структура проекта, для разработчика Flutter, должна быть знакома.
Кроме директории `aurora` где находятся файлы обеспечивающие работу приложения на платформе ОС Аврора:

- `CMakeLists.txt` - приложение Flutter для ОС Аврора имеет платформенную часть на С++, а сборка реализована
  через [CMake](https://cmake.org/).
- `desktop/ru.aurora.app_demo.desktop` - файл интеграции приложения в меню. В нем можно указать название приложения, требуемые права для
  приложения и некоторые другие настройки.
- `icons/*.png` - иконки приложения.
- `main.cpp` - точка входа в приложение для ОС Аврора. Это зачастую шаблонный код для запуска всех необходимых компонентов Flutter и
  приложения.
- `rpm/ru.aurora.app_demo.spec` - файл SPEC можно рассматривать как «рецепт», который утилита rpmbuild использует для фактической сборки
  RPM.

!!! note ""

    Если вы еще не знакомы с Flutter, с ним можно ознакомится на странице
    [документации Flutter](https://docs.flutter.dev/)
    и создать свое первое приложение [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab).

### 2. Сборка приложения

`Flutter CLI` имеет следующие, доступные, участвующие в сборке, команды:

- `pub` - Работа с зависимостями.
- `build` - Команда сборки Flutter.
- `clean` - Очистка временных каталогов.

Для сборки приложения предварительно нужно обновить зависимости приложения.
Сделать это можно командой:

```shell
flutter-aurora pub get
```

Flutter обновит зависимости и выведет отчет:

```shell
Resolving dependencies... 
  flutter_lints 2.0.3 (3.0.2 available)
  lints 2.1.1 (3.0.0 available)
  matcher 0.12.16 (0.12.16+1 available)
  material_color_utilities 0.5.0 (0.11.1 available)
  meta 1.10.0 (1.14.0 available)
  path 1.8.3 (1.9.0 available)
  test_api 0.6.1 (0.7.1 available)
  web 0.3.0 (0.5.1 available)
Got dependencies!
8 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
```

Далее можно собирать приложение командой `build`:

```shell
flutter-aurora build aurora --release
```

Давайте разберем команду:

- `flutter-aurora` - `alias` добавленный при установке.
- `build` - команда сборки приложений.
- `aurora` - платформа для которой сборка будет осуществляться.
- `--release` - тип сборки проекта. Доступны варианта сборки: `--debug`, `--profile`, `--release`.

После успешной выполненной задачи по сборке вы увидите путь к файлу RPM c собранным приложением.

```shell
┌─ Result ────────────────────────────────────────────────────────────────────────────────────┐
│ ./build/aurora/psdk_5.0.0.60/aurora-arm/release/RPMS/ru.aurora.app_demo-0.1.0-1.armv7hl.rpm │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

Этот путь указывает на установочный RPM пакет, который можно
[подписать](../faq/index.md#rpm) и [установить](../faq/index.md#_6)
на эмулятор или устройство.

!!! warning

    На устройствах до `4.0.2.303` требуется установка дополнительных пакетов, от которых зависит работа Flutter.
    Пакеты находятся в установленном Flutter SDK по пути`<flutter-embedder>/dependencies/armv7hl/device`
    в репозитории [Flutter Embedder](https://gitlab.com/omprussia/flutter/flutter-embedder/-/tree/main/dependencies/armv7hl/device).


### Инструменты

Платформа ОС Аврора, как и другие платформы, имеет свои дополнительные инструменты для работы с операционной системой.
Следующие разделы описывают особенности по работе с платформой ОС Аврора.

### 1. Target platform

Собрать проект можно под разные архитектуры.
В команде сборки есть флаг:

`--target-platform`

позволяющий указать целевую архитектуру для сборки.

По умолчанию команда `build` для сборки приложения на платформу ОС Аврора использует архитектуру `armv7hl`.
Всего доступны три архитектуры для сборки на ОС Аврора:

- `armv7hl` - архитектура для устройств, указать можно так `--target-platform aurora-arm`.
- `aarch64` - архитектура для устройств, указать можно так `--target-platform aurora-arm64`.
- `x86_64` - архитектура для эмулятора, указать можно так `--target-platform aurora-x64`.

!!! warning

    На 4е поколение ОС Аврора доступна лишь одна архитектура - `armv7hl`.

### 2. Platform SDK

Для сборки Flutter приложений Flutter CLI использует нативную для платформы SDK - [Platform SDK](https://developer.auroraos.ru/doc/software_development/psdk).
Flutter для ОС Аврора поддерживает 4е и 5е поколение платформ.
Приложения для 4й и 5й ОС Аврора нужно собирать соответствующими версиями Platform SDK.

На персональный компьютер (ПК) для сборки можно установить несколько Platform SDK разных версий.
По умолчанию используется та которая указана в файле `~/.bashrc` в переменной окружения `PSDK_DIR`.
Для сборки приложений отличной от указанной в `PSDK_DIR` в команду сборки был добавлен флаг `--psdk-dir`.

Например, ПК установлено две версии Platform SDK - 4я и 5я.
В переменной окружения `PSDK_DIR` указана 5я версия Platform SDK.
Для сборки приложения под 4е поколение ОС Аврора команда может выглядеть следующим образом:

```shell
flutter-aurora build aurora --release --psdk-dir /home/keygenqt/Aurora_Platform_SDK_4.0.2.303/sdks/aurora_psdk
```

### 3. Добавление в проект

Поддержку платформы ОС Аврора можно добавить в уже существующий проект.
Для этого необходимо в корне проекта выполнить команду Flutter CLI:

```shell
flutter-aurora create --platforms=aurora --org={ORGNAME} .
```

Где `{ORGNAME}` - Имя организации ([Organization name](https://doc.qt.io/qt-5/qcoreapplication.html#organizationName-prop)),
участвует в формировании названия пакета.

Нужно учитывать, что существуют платформо-зависимые плагины, которые разрабатываются под платформу.
В существующем приложении может быть много различных плагинов, все нужно проанализировать.
Ознакомиться с доступными платформо-зависимыми плагинами можно в разделе ["Поддержка"](../support/index.md).
