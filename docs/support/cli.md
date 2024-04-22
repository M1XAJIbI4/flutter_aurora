# Поддержка Flutter CLI

Статус поддержки команд [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli).
Для получения дополнительной справки по любой из команд введите `flutter-aurora help <команда>`.

## Поддерживаемые

| Команда   | Пример                               | Описание                                              | 
|:----------|:-------------------------------------|:------------------------------------------------------|
| build     | `flutter build <DIRECTORY>`          | Команды сборки Flutter.                               |
| clean     | `flutter clean`                      | Удалить каталоги build/ и .dart_tool/.                |
| create    | `flutter create <DIRECTORY>`         | Создать новый проект из шаблонов.                     |
| doctor    | `flutter doctor`                     | Показать статус установленных инструментов.           |
| gen-l10n  | `flutter gen-l10n <DIRECTORY>`       | Создать файлы локализации для проекта Flutter.        |
| pub       | `flutter pub <PUB_COMMAND>`          | Работа с зависимостями.                               |
| test      | `flutter test <DIRECTORY/DART_FILE>` | Запустить тесты в этом пакете.                        |
| upgrade   | `flutter upgrade`                    | Обновить свою копию Flutter.                          |
| downgrade | `flutter downgrade`                  | Понизить версию Flutter до последней активной версии. |

!!! info

    В команду `build aurora` были добавлены аргументы `--target-platform` и `--psdk-dir`.

    `--target-platform` - Целевая платформа (aurora-arm (default), aurora-arm64, aurora-x64).

    `--psdk-dir` - Вы можете указать путь к Aurora Platform SDK (в [документации](https://developer.auroraos.ru/doc/software_development/psdk/setup) по Platform SDK обозначен как PSDK_DIR).

## Ожидают поддержки

| Команда          | Описание                                                                                           | 
|:-----------------|:---------------------------------------------------------------------------------------------------|
| analyze          | Анализ исходного кода проекта.                                                                     |
| assemble         | Собрать ресурсы Flutter.                                                                           |
| attach           | Присоединиться к работающему приложению.                                                           |
| bash-completion  | Вывод сценариев настройки завершения оболочки из командной строки.                                 |
| config           | Настроить параметры Flutter. Чтобы удалить параметр, задайте для него пустую строку.               |
| custom-devices   | Список пользовательских устройств Добавление, удаление, список и сброс пользовательских устройств. |
| devices          | Список всех подключенных устройств.                                                                |
| drive            | Запускает тесты драйвера Flutter для текущего проекта.                                             |
| emulators        | Список, запуск и создание эмуляторов.                                                              |
| install          | Установить приложение Flutter на подключенное устройство.                                          |
| logs             | Показать выходные данные журнала для запуска приложений Flutter.                                   |
| precache         | Заполнить кеш инструмента Flutter двоичными артефактами.                                           |
| run              | Запустить программу Flutter.                                                                       |
| screenshot       | Сделать снимок экрана приложения Flutter с подключенного устройства.                               |
| symbolize        | Обозначить трассировку стека из скомпилированного AOT приложения Flutter.                          |
