# FAQ

## Как установить Flutter для ОС Аврора?

На данный момент установка доступна на Linux и Windows через
[WSL2](https://learn.microsoft.com/en-us/windows/wsl/install#upgrade-version-from-wsl-1-to-wsl-2).
Больше информации можно найти в разделе документации ["Установка"](../install/linux.md).

## В какой IDE работать с Flutter?

Недавно объявили о начале работ над [Aurora Studio](https://aurora.rt.ru/).
Сейчас она в разработке, но уже можно скачать и попробовать использовать ее для работы.
IDE разрабатывается на базе open-source IDE [Visual Studio Code](https://code.visualstudio.com/).
В ожидании релиза, можно использовать любую удобную IDE с поддержкой Flutter.

## А есть ли <?> плагин для ОС Аврора?

Есть разные типы плагинов. Платформо-независимые работают "из коробки",
с доступными платформо-зависимыми можно ознакомится в разделе документации
["Поддержка"](../support/index.md).
По типам плагинов подробнее информацию можно найти в разделе ["Типы плагинов"](../structure/plugins.md#_1).

## Когда ждать последнюю версию Flutter?

Развитие фреймворка Flutter очень динамичное.
Обновление Flutter для ОС Аврора происходит с небольшой задержкой так как мы не находимся сейчас в `upstream` основной разработки Flutter.
На данный момент последний версией является:

![Flutter для ОС Аврора](https://img.shields.io/badge/dynamic/json?color=blue&label=Flutter для ОС
Аврора&query=%24%5B%3A1%5D.name&url=https%3A%2F%2Fgitlab.com%2Fapi%2Fv4%2Fprojects%2F48571227%2Frepository%2Ftags)

## Можно ли работать на macOS?

На данный момент установка доступна на Linux и Windows через WSL2.
Работа на macOS доступна через удаленный доступ с серверу с Linux `x86_64`,
такую работу можно организовать самостоятельно.

## Есть ли Debugger и Hot reload?

Официальной поддержки на данный момент нет, но возможность есть.
Вы можете настроить дебаггер `Dart`, `C++` и `Hot reload` через сторонне приложение
[Aurora CLI](https://github.com/keygenqt/aurora-cli) (только девайсы)
либо вручную.

## Как создать свое перовое приложение?

Для этого нужно установить необходимые инструменты проекта "Flutter для ОС Аврора".
Детальное описание установки можно найти в разделе ["Установка"](../install/linux.md).
Создать шаблон приложения, собрать его, установить на эмулятор/устройство.
Пример и описание создания такого приложения можно найти в разделе ["Примеры"](../examples/build.md).

## Как реализовать плагин для ОС Аврора?

Плагины можно разделить на следующие типы: платформо-независимые, платформо-зависимые и частично-зависимые.
Платформо-независимые плагины реализуются стандартными средствами Flutter.
Подробнее с типами плагинов можно ознакомится в разделе ["Типы плагинов"](../structure/plugins.md#_1).
Создание платформо-зависимых плагинов описано в разделе ["Примеры"](../examples/build.md).

## Как подключить сигналы и слоты Qt

В приложения использующие плагины с поддержкой Qt необходимо добавить поддержку
[Signals & Slots](https://doc.qt.io/qt-5/signalsandslots.html) Qt.
Для этого необходима в файл приложения `aurora/main.cpp` обновить следующим образом:

```c++
#include <flutter/flutter_aurora.h>
#include <flutter/flutter_compatibility_qt.h> // <- Add for Qt
#include "generated_plugin_registrant.h"

int main(int argc, char *argv[]) {
    aurora::Initialize(argc, argv);
    aurora::EnableQtCompatibility(); // <- Enable Qt
    aurora::RegisterPlugins();
    aurora::Launch();
    return 0;
}
```

## Какую операционную систему лучше использовать?

На данный момент основной операционной системой для разработки приложений/плагинов является Linux.
Рекомендованный дистрибутив - [Ubuntu](https://ubuntu.com/), на различных дистрибутивах есть нюансы по его использованию.

## Что такое Flutter Embedder?

Это библиотека, написанная на С++, которая обеспечивает взаимодействие Flutter Engine с операционной системой Аврора.
Flutter для ОС Аврора с версии `3.16.2-2` получил автоматизацию по работе с этим компонентом и устанавливается/обновляется автоматически.
Детальнее узнать о назначении Flutter Embedder можно в разделе ["Компоненты"](../structure/components.md#flutter-embedder).

## Подскажите как подключить хедеры Flutter Embedder к IDE?

Создать в корне проекта файл `.vscode/c_cpp_properties.json`

```json
{
  "configurations": [
    {
      "name": "Linux",
      "includePath": [
        "${workspaceFolder}/**",
        "<target-path>/usr/include",
        "<target-path>/usr/include/flutter-embedder"
      ],
      "defines": [
        "__ARM_PCS_VFP"
      ],
      "compilerPath": "/usr/bin/g++",
      "cStandard": "c17",
      "cppStandard": "c++17",
      "intelliSenseMode": "clang-x64"
    }
  ],
  "version": 4
}
```

Можно попробовать найти <target-path> так:

```shell
find / -name flutter-embedder -type d 2> /dev/null
```

## Как отформатировать С++ код?

Отформатировать С++ код поможет [clang-format](https://clang.llvm.org/docs/ClangFormat.html).

Его можно установить через `apt`:

```shell
sudo apt install clang-format
```

Перейти в папку с C++ проектом и выполнить:

```shell
find . -type f -name "*.h" -o -name "*.cpp" -exec clang-format -i {} \;
```

## Что такое Flutter CLI?

Это интерфейс [командной строки Flutter](https://docs.flutter.dev/reference/flutter-cli), 
который обеспечивает основную работу с фреймворком.
Ознакомится с поддержкой команд для платформы ОС Аврора можно в разделе ["Flutter CLI"](../support/cli.md).

## Что такое подпись RPM пакета?

Для того что бы установить RPM пакет на ОС Аврора его нужно подписать.
Для этого вам понадобится ключевая пара - ключ и сертификат.
Детально информацию о подписи можно найти в
документации ["Подписывание установочных пакетов"](https://developer.auroraos.ru/doc/software_development/guides/package_signing).

## Что такое песочница приложения?

Приложение в ОС Аврора запускается в своем окружении которое ограничено в правах и доступе.
Важно тестировать работоспособность ваших приложений в защищенном окружении.
Запустить приложение в "песочнице" можно с иконки либо из командной строки устройства:

```shell
invoker --type=qt5 {package}
```

- `{package}` - идентификатор вашего приложения, например `ru.auroraos.app`.

## Как собрать приложение на ОС Аврора 5 и Аврора 4?

Flutter для ОС Аврора поддерживает работу с несколькими [Platform SDK](https://developer.auroraos.ru/doc/software_development/psdk) для
сборки приложений.
Детали по такой сборки вы можете найти в разделе ["Примеры"](../examples/build.md#2-platform-sdk).

## Как установить приложение на эмулятор/устройство?

Получить доступ к устройству и эмулятору можно через протокол SSH.
Загрузив RPM пакет любым удобным способом (scp, filezilla и т.д.), вы можете установить приложение пакетным менеджером `pkcon`:

```shell
devel-su pkcon install-local *.rpm -y
```

## Как запустить приложение на эмуляторе/устройстве?

Есть два варианта запуска приложения: в защищенном окружении и вне его.

Запуск в защищенном окружении:

```shell
invoker --type=qt5 {package}
```

Запуск вне защищенного окружения:

```shell
/usr/bin/{package}
```

- {package} - идентификатор вашего приложения, например `ru.auroraos.app`.

## У меня не стартует приложение, что делать?

В первую очередь запустить приложение вне защищенного окружения в подключенном терминале по SSH
к устройству / эмулятору и посмотреть вывод информации о запуске.
Если это эмулятор, попробовать сменить локаль телефона - известная проблема, которая решается.
Для более детального отсчета можно воспользоваться приложением `journalctl` доступном на
устройстве / эмуляторе:

```shell
journalctl -f 
```

## Как узнать тип подключенных плагинов к приложению?

Плагины можно разделить на 2 основных типа: платформо-зависимые и платформо-независимые.
На [pub.dev](https://pub.dev/), к сожалению нет такого разделения,
информацию о типе плагина можно получить в `pubspec.yaml` плагина по ключевому слову `platforms`.
Нужно учитывать что плагин может зависеть от платформо-зависимых плагинов.

## Можно ли написать плагин для ОС Аврора без С++?

На ОС Аврора большое количество библиотек имеют интерфейс [D-Bus](https://www.freedesktop.org/wiki/Software/dbus/).
На Flutter для ОС Аврора работает плагин [dbus](https://pub.dev/packages/dbus), через который можно создать
платформо-зависимый плагин без использования C++.

## У меня есть предложение/идея где о ней сообщить?

Все предложения и идеи можно оставить в разделе [issue](https://gitlab.com/omprussia/flutter/flutter/-/issues) проекта.

## Я нашел баг куда о нем сообщить?

Всю информацию о проблемах с которыми сталкиваетесь можно оставить в разделе [issue](https://gitlab.com/omprussia/flutter/flutter/-/issues)
проекта.
Уточнить баг это или фича можно в публичном чате сообщества [Aurora Developers](https://t.me/aurora_devs).

## Где можно задать вопрос?

Простой вопрос можно задать в публичном чате сообщества [Aurora Developers](https://t.me/aurora_devs).
Если вопрос требует детального описания и ответа его лучше задать в разделе [issue](https://gitlab.com/omprussia/flutter/flutter/-/issues)
проекта.

## Как получить телефон?

Получить устройство можно, подав заявку в [программу бета-тестирования Аврора](https://auroraos.ru/beta).
Желающих попасть в программу большое количество, над расширением программы работы ведутся.
Для ускорения процесса можно указать, что вы являетесь программистом, и цель получения устройства.

## Flutter 3.16.2-1 -> 3.16.2-2

С обновлением `3.16.2-2` [Flutter Embedder](./index.md#flutter-embedder) получил общий интерфейс Flutter -
[Client Wrapper](../structure/plugins.md#client-wrapper).
Старым платформо-зависимым плагинам нужно обновить взаимодействие с Flutter Embedder.
Все плагины в основном репозитории - [Flutter Plugins](https://gitlab.com/omprussia/flutter/flutter-plugins) были обновлены.
Со списком плагинов можно ознакомится в разделе ["Поддержка"](../support/index.md).

Обновление интерфейса затронуло хедеры в `3.16.2-2`.
Для демонстрации изменений было написано [демо приложение](https://gitlab.com/omprussia/flutter/flutter-plugins/-/tree/main/demo/client_wrapper_demo?ref_type=heads),
в котором используются все актуальные конструкции по работе с Client Wrapper.

Все платформенные функции Flutter Embedder из разрозненных хедеров:

```c++
#include <flutter/platform-events.h>
#include <flutter/platform-methods.h>
```

были перенесены в один:

```c++
#include <flutter/flutter_aurora.h>
```

Также обратите внимание на обновленную функцию `main` приложения.

Было:

```c++
#include <flutter/application.h>
#include "generated_plugin_registrant.h"

int main(int argc, char *argv[]) {
    Application::Initialize(argc, argv);
    RegisterPlugins();
    Application::Launch();
    return 0;
}
```

Стало:
```c++
#include <flutter/flutter_aurora.h>
#include "generated_plugin_registrant.h"

int main(int argc, char *argv[]) {
    aurora::Initialize(argc, argv);
    aurora::RegisterPlugins();
    aurora::Launch();
    return 0;
}
```

## Форматирование Dart

Для форматирования кода Dart мы используем [dart format](https://dart.dev/tools/dart-format) размером строки в `120` символов.
Размер строки можно указать через параметр `--line-length`.
Версия Dart должна соответствовать последнему релизу Flutter для ОС Аврора,
который расположен в папке `bin` установленного Flutter.

Команда на форматирование может выглядеть следующим образом:

```shell
dart-aurora format --line-length=120 .
```

## Форматирование C++

Для форматирования кода С++ мы используем [clang-format](https://clang.llvm.org/docs/ClangFormat.html).
Конфигурацию используем с [Flutter Engine](https://github.com/flutter/engine/blob/main/.clang-format)
c небольшими изменениями [.clang-format](https://gitlab.com/omprussia/flutter/flutter/-/blob/main/.clang-format).

Команда на форматирование может выглядеть следующим образом:

```shell
clang-format --style=file:$HOME/Downloads/clang-format.txt --style="{ReflowComments: false}" -i client_wrapper_demo_plugin.h
```

Для форматирования всех файлов в папке можно использовать следующую команду:

```shell
find . -type f -iname '*.h' -o -iname '*.cpp' | xargs \
clang-format --style=file:$HOME/Downloads/clang-format.txt --style="{ReflowComments: false}" -i
```

<style>
@media screen and (min-width: 1220px) {
    .md-content {
        width: 70%;
        flex-grow: initial;
    }
    .md-sidebar {
        width: 30%;
    }
    .md-sidebar__inner {
        padding-right: 20px !important;
    }
}
</style>
