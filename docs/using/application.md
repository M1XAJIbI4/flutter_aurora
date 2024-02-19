# Flutter приложение "Hello, World!"

Приложение, написанное на Dart с использованием Flutter SDK, например, [Fluttery ToDo](https://gitlab.com/omprussia/flutter/fluttery-todo).
На данный момент любое приложение Flutter может быть собрано под ОС Аврора, исключением являются лишь те, которые имеют в зависимостях нереализованные платформо-зависимые плагины.

!!! info

    Для демонстрации создания платформо-зависимого пакета для ОС Аврора типа был написан и опубликован проект
    [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages), в котором имеется приложение "Hello, World!".
    Полную статью с описанием проекта можно найти на Хабр - [Flutter на ОС Аврора](https://habr.com/ru/articles/761176/).

Проект [Demo Dart Packages](https://gitlab.com/omprussia/flutter/demo-dart-packages) содержит в себе приложение "Hello, World!".
Создать приложение Flutter для ОС Аврора можно командой:

```shell
flutter-aurora create --platforms=aurora --template=app --org=<ORG_NAME> <APPNAME>
```

- `<ORG_NAME>` - название организации
- `<APPNAME>` - название приложения

Данная команда генерирует базовый пример Flutter приложения с настроенным окружением для сборки под ОС Аврора. 
Структура файлов и каталогов проекта имеет следующий вид:

```shell
├── analysis_options.yaml
├── aurora
│   ├── CMakeLists.txt
│   ├── desktop
│   │   └── <ORG_NAME>.<APPNAME>.desktop
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
│       └── <ORG_NAME>.<APPNAME>..spec
├── lib
│   └── main.dart
├── pubspec.lock
├── pubspec.yaml
├── README.md
└── <APPNAME>.iml
```

Описание и лицензия проекта настраивается в файле `<project>/aurora/rpm/<ORGNAME>.<APPNAME>.spec`. 
Название проекта, которое будет отображаться в сетке приложений, описание проекта и список разрешений, необходимых для работы приложения, можно указать в файле `<project>/aurora/desktop/<ORGNAME>.<APPNAME>.desktop`.
Иконки приложения находятся в папке `<project>/aurora/icons`. Всё остальное стандартно для Flutter приложений.

## Добавление поддержки

Для того чтобы добавить поддержку ОС Аврора в уже имеющееся Flutter приложение, перейдите в папку с Flutter проектом и выполните следующую команду:

```shell
flutter-aurora create --platforms=aurora --org=<ORGNAME> .
```

## Сборка приложения

Выполните команду `flutter-aurora doctor`, чтобы убедиться, что ваше окружение подготовлено для сборки под ОС Аврора.

Запустите сборку проекта в необходимом вам режиме:

```shell
flutter-aurora build aurora --debug
flutter-aurora build aurora --profile
flutter-aurora build aurora --release
```

Если у вас несколько Platform SDK, для сборки можно указать путь `<PATH>` к нужной через параметр `--psdk-dir`:

```shell
flutter-aurora build aurora --debug --psdk-dir <PATH>
```

Для сборки отличных от таргета `armv7hl` добавлен параметр `--target-platform`.
Доступны три `target-platform`:

* `aurora-arm` (default) - для архитектуры `armv7hl`
* `aurora-arm64` - для архитектуры `aarch64`
* `aurora-x64` - для архитектуры `x86_64`

Команда с параметром `--target-platform` может выглядеть так:

```shell
flutter-aurora build aurora --debug --target-platform aurora-arm
```

!!! info
    
    Во время процесса сборки может потребоваться ввести пароль от супер-пользователя для работы с Platform SDK.
    Для того чтобы убрать запрос супер-пользователя, ознакомьтесть с [Установка Platform SDK](../install/linux.md#platform-sdk).

После успешной сборки будет выведен путь к собранному RPM пакету.

```shell
flutter-aurora build aurora --release

  Building Aurora application...

  ┌─ Result ────────────────────────────────────────────────────────┐
  │ ./build/aurora/arm/release/RPMS/com.example.example.armv7hl.rpm │
  └─────────────────────────────────────────────────────────────────┘
```

Далее пакет следует подписать, описание процесса можно найти здесь - [Подписывание установочных пакетов](https://developer.auroraos.ru/doc/software_development/guides/package_signing).
После этого можно установить приложение на устройство с ОС Аврора (`4.0.2.269` и выше).
