# Gitflow

С версии Flutter `3.16.2-1` были добавлены Changelog во все проекты Flutter по поддержке ОС Аврора:

* [Flutter](https://gitlab.com/omprussia/flutter/flutter)
* [Flutter Embedder](https://gitlab.com/omprussia/flutter/flutter-embedder)
* [Flutter Engine](https://gitlab.com/omprussia/flutter/flutter-engine)
* [Flutter Plugins](https://gitlab.com/omprussia/flutter/flutter-plugins)

Основные ветки проектов - `main`. Все изменения стекаются сюда.
Версия фиксируется тегом.

## Flutter и Engine

В теге указана версия [Flutter SDK](https://github.com/flutter/flutter) и версия ее модификации `<flutter sdk version>-<update version>` (первая 0 - не указывается).
Например:

* Обновляем Flutter для ОС Аврора на Flutter SDK версии `3.20.10`, тег нашей версии будет - `3.20.10`.
* Обновляем Flutter для ОС Аврора без изменения версии Flutter SDK, тег нашей версии будет - `3.20.10-1`.

## Flutter Embedder

В теге указана версия [Flutter SDK](https://github.com/flutter/flutter) и версия flutter-embedder библиотеки `<flutter sdk version>-<flutter-embedder version>`.
Например:

* Обновляем Flutter Embedder c версией `2.0.0` с текущей версией Flutter SDK `3.20.10`, получим - `3.20.10-2.0.0`.

## Flutter Plugins

Каждый плагин имеет свою версию и свой тег фиксации версии.
В теге указывается название плагина (`name` в `pubspec.yaml`) и его версия через тире: `<name>-<plugin version>`.
Например:

* Плагин xdga_directories с версий 0.0.2 можно зафиксировать тегом `xdga_directories-0.0.2`.

## Changelog

Changelog генерируется на основе тегов и коммитов приложением [Changeln](https://snapcraft.io/changeln).
В проектах имеется 2 файла настройки приложения Changeln:

* `changeln.yaml` - настройка тегов git и тегов комментариев.
* `changeln.template` - шаблон генерации changelog.

### Теги комментариев

В changelog фиксируются комментарии только с указанными тегами.
Теги указываются в файле `changeln.yaml`. 
У нас они следующие:

* `[bug]` - был исправлен баг.
* `[change]` - было внесено исправление функционала.
* `[feature]` - добавлен новый функционал.

Комментарий должен быть не слишком длинным, но нести в себе информацию, которая будет потом отражена в changelog.
Комментарий должен быть на английском, международном, языке.
Пример комментария, который попадет в changelog после фиксации тегом версии:

`[bug] A crash after opening a popup has been fixed.`

### Генерация changelog

Для генерации `CHANGELOG.md` нужно установить приложение Changeln:

```shell
sudo snap install changeln
```

И выполнить команду генерации в корне проекта (для плагинов корнем является папка плагина):

```shell
changeln -t ./changeln.template \
    -c ./changeln.yaml \
    -p ./ \
    changelog markdown
```


