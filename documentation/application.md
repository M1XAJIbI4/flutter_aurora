# Flutter приложение "Hello World"

Приложение написанное на Dart с использованием Flutter SDK, например [Fluttery ToDo](https://gitlab.com/omprussia/flutter/fluttery-todo). На данный момент любое приложение Flutter может быть собрано под ОС Аврора, исключением являются лишь те корыте имеют в зависимостях не реализованные платформо-зависимые плагины. Весь список готовых и проверенных плагинов можно найти в репозитории "[Flutter Plugins](https://gitlab.com/omprussia/flutter/flutter-plugins)".

> Для демонстрации создания платформо-зависимого пакета для ОС Аврора типа был написан и опубликован проект "[Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages)" в котором имеется приложение "Hello World". Полную статью с описанием проекта можно найти на Хабр - "[Flutter на ОС Аврора](https://habr.com/ru/articles/761176/)".  

Проект "[Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages)" содержит в себе приложение "Hello World". Создать приложение Flutter для ОС Аврора можно командой:

```shell
flutter-aurora create --platforms=aurora --template=app --org=<ORG_NAME> <APPNAME>
```

- `<ORG_NAME>` - название организации
- `<APPNAME>` - название приложения

Данная команда генерирует базовый пример Flutter приложения с настроенным окружением для сборки под ОС Аврора. Структура файлов и каталогов проекта имеет следующий вид:

```shell
├── analysis_options.yaml
├── aurora
│   ├── CMakeLists.txt
│   ├── desktop
│   │   └── com.hello.world.desktop
│   ├── flutter
│   │   ├── generated_plugin_registrant.cpp
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   ├── icons
│   │   ├── 108x108.png
│   │   ├── 128x128.png
│   │   ├── 172x172.png
│   │   └── 86x86.png
│   ├── main.cpp
│   └── rpm
│       └── com.hello.world.spec
├── lib
│   └── main.dart
├── pubspec.lock
├── pubspec.yaml
├── README.md
└── world.iml
```

Описание и лицензия проекта настраивается в файле `<project>/aurora/rpm/<ORGNAME>.<APPNAME>.spec`. Название проекта, которое будет отображаться в сетке приложений, описание проекта и список разрешений, необходимых для работы приложения, можно указать в файле `<project>/aurora/desktop/<ORGNAME>.<APPNAME>.desktop`. Иконки приложения находятся в папке `<project>/aurora/icons`. Всё остальное стандартно для Flutter приложений.

## Добавление поддержки ОС Аврора в имеющийся проект

Для того что бы добавить поддержку ОС Аврора в уже имеющиеся Flutter приложение перейдите в папку с Flutter проектом и выполните следующую команду:

```shell
flutter-aurora create --platforms=aurora --org=<ORGNAME> .
```

## Сборка Flutter приложения

Выполните команду `flutter-aurora doctor`, чтобы убедиться, что ваше окружение подготовлено для сборки под ОС Аврора.

> На данный момент поддерживается сборка только под архитектуру `armv7hl`

Выполните следующую команду, чтобы выставить в Platform SDK таргет `armv7hl` по умолчанию.

```shell
# Определите название armv7hl таргета
aurora_psdk sdk-assistant list

  AuroraOS-4.0.2.89-base
  ├─AuroraOS-4.0.2.89-base-aarch64
  ├─AuroraOS-4.0.2.89-base-armv7hl <- <TARGET>
  └─AuroraOS-4.0.2.89-base-i486

aurora_psdk sb2-config -d <TARGET>
```

Запустите сборку проекта в необходимом вам режиме:

```shell
flutter-aurora build aurora --debug
flutter-aurora build aurora --profile
flutter-aurora build aurora --release
```

> Во время процесса сборки может потребоваться ввести пароль от супер-пользователя для работы с Platform SDK

После успешной сборки будет выведен путь к собранному RPM пакету.

```shell
flutter-aurora build aurora --release

  Building Aurora application...

  ┌─ Result ────────────────────────────────────────────────────────┐
  │ ./build/aurora/arm/release/RPMS/com.example.example.armv7hl.rpm │
  └─────────────────────────────────────────────────────────────────┘
```

Далее пакет следует подписать, описание процесса можно найти здесь - [Подписывание установочных пакетов](https://developer.auroraos.ru/doc/software_development/guides/package_signing). После этого можно установить приложение на устройство с ОС Аврора (4.0.2.269 и выше).
