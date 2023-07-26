## Использование Flutter SDK для разработки под ОС Аврора

Для ОС Аврора доступны следующие шаблоны проектов:

- `app` - Приложение
- `plugin` - Platform Channel плагин
- `plugin_ffi` - FFI плагин

## Генерация проекта приложения

Для генерации проекта приложения выполните следующую команду, указав шаблон, название организации и название проекта:

```shell
$ flutter-aurora create --platforms=aurora --template=app --org=<ORG_NAME> <APPNAME>
```

Данная комманда сгенерирует базовый пример Flutter приложения с настроенным окружением для сборки под ОС Аврора.

В файле `aurora/rpm/<ORGNAME>.<APPNAME>.spec` вы можете указать описание и лицензию проекта.

В файле `aurora/desktop/<ORGNAME>.<APPNAME>.desktop` вы можете указать имя проекта, которое будет отображаться в сетке приложений, описание проекта и список разрешений, необходимых для работы приложения.

В папке `aurora/icons` вы можете разместить свою иконку приложения, которая будет отображатсья в сетке приложений.

## Генерация проекта плагина

Для генерации проекта Platform Channel плагина выполните следующую команду,
указав шаблон и название плагина:

```shell
$ flutter-aurora create --platforms=aurora --template=plugin <PLUGIN_NAME>
```

Данная комманда сгенерирует базовый пример Platform Channel плагина и простой пример приложения, взаимодействующего с этим плагином, в папке `example`.

> На данный момент не поддерживаются сигналы и слоты в плагинах, использующих Qt. Ведутся работы для добавления поддержки.

При использовании каких либо зависимостей в плагине необходимо добавить эту зависимость в `.spec`
файле приложения, чтобы при сборке приложения все зависимости автоматически установились.

Например при разработке плагина `sqflite` в `.spec` файл была добавлена следующая строчка:

```
  BuildRequires: cmake
+ BuildRequires: pkgconfig(sqlite3)
  BuildRequires: pkgconfig(flutter-embedder)
```

## Генерация проекта FFI плагина

Для генерации проекта FFI плагина выполните следующую команду,
указав шаблон и название плагина:

```shell
$ flutter-aurora create --platforms=aurora --template=plugin_ffi <PLUGIN_NAME>
```

Данная комманда сгенерирует базовый пример FFI плагина и простой пример приложения, взаимодействующего с этим плагином, в папке `example`.

При использовании зависимостей в FFI плагине следедует не забыть
добавить зависимость в `.spec` файл приложения, по [аналогии](#генерация-проекта-плагина) с Platform Channel плагинами.

## Добавление поддержки ОС Аврора в имеющийся проект

Перейдите в папку с Flutter проектом и выполните следующую команду:

```shell
$ flutter-aurora create --platforms=aurora --org=<ORGNAME> .
```

## Cборка Flutter приложения

Выполните команду `flutter-aurora doctor`, чтобы убедиться, что ваше окружение подготовленно для сборки под ОС Аврора.

> На данный момент поддерживается сборка только под архитектуру `armv7hl`

Выполните следующую команду, чтобы выставить в Platform SDK таргет `armv7hl` по умолчанию.

```shell
# Определите название armv7hl таргета
$ aurora_psdk sdk-assistant list

  AuroraOS-4.0.2.89-base
  ├─AuroraOS-4.0.2.89-base-aarch64
  ├─AuroraOS-4.0.2.89-base-armv7hl <- <TARGET>
  └─AuroraOS-4.0.2.89-base-i486

$ aurora_psdk sb2-config -d <TARGET>
```

Запустите сборку проекта в необходимом вам режиме:

```shell
$ flutter-aurora build aurora --debug
$ flutter-aurora build aurora --profile
$ flutter-aurora build aurora --release
```

> Во время процесса сборки может потребоваться ввести пароль от супер-пользователя для работы с Platform SDK

После успешной сборки будет выведен путь к собранному RPM пакету.

```shell
$ flutter-aurora build aurora --release

  Building Aurora application...

  ┌─ Result ────────────────────────────────────────────────────────┐
  │ ./build/aurora/arm/release/RPMS/com.example.example.armv7hl.rpm │
  └─────────────────────────────────────────────────────────────────┘
```

## Установка на устройство

> На данный момент Flutter SDK не поддерживает запуск приложений в эмуляторе. Единственный способ проверить работоспособность приложения - запуск на реальном устройстве.

Все RPM пакеты, которые устанавливаются на устройство с ОС Аврора, должны быть подписаны. Подробнее о процессе подписи RPM пакетов можно почитать в [документации](https://developer.auroraos.ru/doc/software_development/guides/package_signing).

Выполните следующую команду, чтобы подписать собранный RPM пакет:

```shell
$ aurora_psdk rpmsign-external sign --key <KEY_PATH> --cert <CERT_PATH> <RPM_PATH>
```

После подписывания RPM пакета необходимо включить на устройстве режим разработчика.

Если вы используете ОС Аврора 4.0.2 также необходимо один раз установить на устройство пакеты совместимости.

```shell
$ scp ~/.local/opt/flutter/bin/cache/artifacts/aurora/arm/device/compatibility/*.rpm defaultuser@<DEVICE_IP>:/home/defaultuser/Downloads

$ ssh defaultuser@<DEVICE_IP>
$ devel-su

$ pkcon install-local /home/defaultuser/Downloads/maliit-*.rpm -y
```

Скопируйте подписанный RPM пакет на устройтсво по SSH:

```shell
$ scp <RPM_PATH> defaultuser@<DEVICE_IP>:/home/defaultuser/Downloads
```

Установите скопированный RPM пакет на устройстве:

```shell
$ ssh defaultuser@<DEVICE_IP>
$ devel-su
$ pkcon install-local /home/defaultuser/Downloads/<COPIED_RPM_NAME> -y
```

После установки приложения вы можете запустить его из сетки приложений.

# Подключение и использование плагинов

Большинство плагинов в Flutter написаны на языке Dart и не зависят от платформы. Такие плагины подключаются командой:

```shell
$ flutter pub add <PLUGIN_NAME>
```

Однако во Flutter присутствуют и платформозависимые плагины, например `path_provider`.
Для части таких плагинов имеется имплементация под ОС Аврора. Полный список поддерживаемых платформозависимых плагинов вы сможете найти в репозитории [flutter-plugins](#todo).

Для работы с платформозависимым плагином необходимо также подключить помимо его имплементацию под ОС Аврора.

Пример подключения платформозависимого плагина:

```yaml
dependencies:
    path_provider: ^2.0.7
    path_provider_aurora:
        git:
            url: #todo
            path: packages/path_provider/path_provider_aurora
```

Информацию по подключению и использованию платформозависимых плагинов в ОС Аврора вы найдете в репозитории [flutter-plugins](#todo) в файле README.md в папке конкретного плагина.
