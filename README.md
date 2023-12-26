# Flutter SDK для ОС Аврора

![preview.png](documentation/data/preview.png)

[Flutter SDK](https://github.com/flutter/flutter) с поддержкой платформы ОС Аврора для создания приложений Flutter.

[Flutter](https://flutter.dev/) — это SDK Google для создания красивых и быстрых пользовательских интерфейсов для мобильных устройств, Интернета и настольных компьютеров на основе единой базы кода. Flutter работает с существующим кодом, используется разработчиками и организациями по всему миру, он бесплатен и имеет открытый исходный код.

Flutter SDK для ОС Аврора не состоит в [`upstream`](https://en.wikipedia.org/wiki/Upstream_(software_development)), и платформа ОС Аврора не доступна в официальной сборке Flutter. Поэтому установка происходит отличным от основного метода установки.

## Установка

* [Установка на Linux](documentation/install_linux.md)
* [Установка на Windows (WSL2)](documentation/install_wsl2.md)

## Использование

При установке Flutter SDK для ОС Аврора во избежание коллизий с `upstream` версией Flutter исходная CLI команда `flutter` меняется на `flutter-aurora`. Поддерживается только интерфейс командной строки. Сборка требует права суперпользователя так как зависит от [Аврора Platform SDK](https://developer.auroraos.ru/doc/software_development/psdk).

```shell
# Проверка установленных инструментов
flutter-aurora doctor

# Создание нового проекта
flutter-aurora create --platforms=aurora --template=app <NAME>

# Сборка приложения
flutter-aurora build aurora --release
```

Подробнее о поддержке CLI смотрите раздел "[Flutter CLI на ОС Аврора](documentation/cli.md)".

### IDE

На данный момент специальной поддержки Flutter для ОС Аврора не ведется. Поддержка Flutter доступна в IntelliJ IDEA Community & Visual Studio Code стандартными для Flutter и Dart плагинами.

## Тестирование

Тестирование проектов Flutter описано в документации "[Testing Flutter apps](https://docs.flutter.dev/testing/overview)". Примеры тестов можно получить при создании шаблона проекта для платформы ОС Аврора.

## Отладка

На данный момент изучение этого вопроса находится в очереди. Вы можете помочь, оставив сообщение в раздел [issue](https://gitlab.com/omprussia/flutter/flutter/-/issues) о встреченных вами проблем с отладкой и их решению.

## Шаблоны

Flutter SDK позволяет создавать стартовые шаблоны для проектов на основе которых легко начать нужный вам проект:

```shell
flutter-aurora create --platforms=aurora --template=<KEY> --org=<ORG_NAME> <APPNAME>
```

- `<KEY>` - Тип шаблона, их три: `app` - приложение, `plugin` - плагин, `plugin_ffi` - плагин FFI.
- `<ORG_NAME>` - Название организации, написавшей это приложение.
- `<APPNAME>` - Имя этого приложения в нижнем регистре без пробелов и символов.

Всего можно отметить пять видов возможных проектов на Flutter для ОС Аврора:

- [Приложение](documentation/application.md);
- [Dart package](https://gitlab.com/omprussia/flutter/flutter-plugins/-/blob/master/documentation/dart_package.md);
- [Plugin package](https://gitlab.com/omprussia/flutter/flutter-plugins/-/blob/master/documentation/plugin_package.md);
- [Qt plugin package](https://gitlab.com/omprussia/flutter/flutter-plugins/-/blob/master/documentation/qt_plugin_package.md);
- [FFI Plugin package](https://gitlab.com/omprussia/flutter/flutter-plugins/-/blob/master/documentation/ffi_plugin_package.md).

## Плагины для ОС Аврора

Мы находимся в процессе создания необходимых плагинов для разработки всевозможных приложений пользователей. Все доступные на данный момент плагины вы можете найти в репозитории "[Flutter Plugins](https://gitlab.com/omprussia/flutter/flutter-plugins)". Если плагин который вы ищете еще не реализован для ОС Аврора оставьте сообщение в [issue](https://gitlab.com/omprussia/flutter/flutter-plugins/-/issues) либо рассмотрите возможность создать пакет самостоятельно.

## Демонстрационное приложение

Все плагины имеют общее демонстрационное приложение **Flutter example packages**. Оно предназначено для демонстрации работы как платформо-зависимых, так и нет плагинов/пакетов. Подробнее вы можете узнать о приложении в репозитории "[Flutter Plugins](https://gitlab.com/omprussia/flutter/flutter-plugins)".

## Wiki

В [Wiki](documentation/wiki.md) собраны популярные вопросы о Flutter для ОС Аврора и ответы на них. Все вопросы и предложения приветствуем, оставляете сообщения в [issue](https://gitlab.com/omprussia/flutter/flutter/-/issues) будем разбирать каждый из них по возможности. Спасибо.

## Вклад

Этот проект поддерживается сообществом, и мы будем рады вашему вкладу и активности, оставляйте ваши вопросы, отзывы в [issue](https://gitlab.com/omprussia/flutter/flutter/-/issues) либо вашу работу в [мерж-реквесты](https://gitlab.com/omprussia/flutter/flutter/-/merge_requests). Вместе мы сделаем Flutter для платформы ОС Аврора доступнее для всех желающих.
