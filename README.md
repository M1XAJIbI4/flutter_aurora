<div align="center">
    <img src="data/preview.png" />
</div>

# Flutter SDK для ОС Аврора

[Flutter SDK](https://github.com/flutter/flutter) с поддержкой платформы ОС Аврора для создания Flutter приложений.

# Установка

* [Установка для Linux](https://gitlab.com/omprussia/flutter/flutter/-/blob/aurora/documentation/installation.md?ref_type=heads)
* [Установка для Windows (WSL2)](https://gitlab.com/omprussia/flutter/flutter/-/blob/aurora/documentation/installation.md?ref_type=heads)

# Использование

На данный момент поддерживается только интерфейс командной строки.

```shell
# Проверка установленных инструментов
$ flutter-aurora doctor

# Создание нового проекта
$ flutter-aurora create --platforms=aurora --org=<ORGNAME> <APPNAME>

# Сборка приложения
$ flutter-aurora build aurora --release
```

Подробнее про использование можно прочитать на странице [«Использование Flutter SDK для ОС Аврора»](https://gitlab.com/omprussia/flutter/flutter/-/blob/aurora/documentation/usage.md?ref_type=heads).

# IDE

Для разработки вы можете использовать свою любимую IDE.

- [VS Code](https://code.visualstudio.com/)
- [Android Studio](https://developer.android.com/studio/install)
- [IntelliJ IDEA](https://www.jetbrains.com/idea/)

На данный момент нет поддержки ОС Аврора в популярных IDE и плагинах для разработки на Flutter, поэтому для создания и сборки проекта под ОС Аврора необходимо использовать интерфейс командной строки.

# Тестирование

Тестирование проектов описано на странице [«Testing Flutter Apps»](https://docs.flutter.dev/testing/overview). Примеры тестов генерируются при создании шаблона проекта для ОС Аврора.

# Отладка

На данный момент отладка проектов для ОС Аврора не реализована. Вы можете помочь сообществу, создав [issue](https://gitlab.com/omprussia/flutter/flutter/-/issues) по поводу ваших идей для решений вопросов отладки проектов.

# Шаблоны

Flutter SDK позволяет создавать стартовые шаблоны проектов, на основе которых вы сможете легко создать проект.

### Приложение

```shell
$ flutter-aurora create --platforms=aurora --org=<ORGNAME> <APPNAME>
```

### Плагин

```shell
$ flutter-aurora create --platforms=aurora --tempalte=plugin <PLUGIN>
```

### FFI плагин

```shell
$ flutter-aurora create --platforms=aurora --tempalte=plugin_ffi <PLUGIN>
```

# Плагины для ОС Аврора

Платформозависимые плагины для ОС Аврора разрабатываются в рамках репозитория [Flutter Plugins](https://gitlab.com/omprussia/flutter/flutter-plugins).

Если плагин, который вы ищете, еще не реализован для ОС Аврора, оставьте [issue](https://gitlab.com/omprussia/flutter/flutter-plugins/-/issues), либо рассмотрите возможность поддержать сообщество, реализовав плагин и опубликовав его в репозитории [Flutter Plugins](https://gitlab.com/omprussia/flutter/flutter-plugins).

Все плагины объеденены в общее [демонстрационное приложение](https://gitlab.com/omprussia/flutter/flutter-plugins/-/tree/master/example), предназначеное для демонстрации и проверки работоспособности плагинов на платформе ОС Аврора. Подробнее про это вы можете узнать в репозитории [Flutter Plugins](https://gitlab.com/omprussia/flutter/flutter-plugins).

# Вклад сообщества

Этот проект поддерживается сообществом. Оставляйте ваши вопросы и отзывы в [issues](https://gitlab.com/omprussia/flutter/flutter/-/issues) проекта,
либо публикуйте ваши наработки в репозиторий через [merge request](https://gitlab.com/omprussia/flutter/flutter/-/merge_requests).

Мы будем рады любому вашему вкладу в развитие проекта.
