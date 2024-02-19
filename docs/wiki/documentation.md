# Документация

Документация использует [GitLab Pages](https://docs.gitlab.com/ee/user/project/pages), [MkDocs](https://www.mkdocs.org/) и [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

GitLab CI настроен на главную ветку и обновляет документацию при изменении ветки `main`.
Это значит, что все изменения попадут в документацию сразу же при изменении ветки `main`.

!!! warning

    Изменения документации, затрагивающие функционал будущих версий, нужно мержить только при фиксации версии Flutter SDK.

## Локальный запуск

Для работы с документацией потребуется установить `python` и `pip`:

```shell
sudo apt install python3 pip
```

И приложения, позволяющие генерировать статический сайт с документацией, - `mkdocs` и `mkdocs-material`:

```shell
pip install mkdocs mkdocs-material
```

Для локальной работы можно выполнить команду из корня проекта [Flutter](https://gitlab.com/omprussia/flutter/flutter):

```shell
mkdocs serve
```
