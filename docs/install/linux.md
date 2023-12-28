# Установка на Linux

Для настройки рабочего места следует выполнить следующие шаги:

- Установить Flutter SDK
- Установить Platform SDK
- Установка пакетов для сборки Flutter
- Установка пакетов для работы Flutter

## Установка Flutter SDK

Установка будет производиться на систему Ubuntu 22.04.
На других системах Linux возможны некоторые незначительные отклонения от документации.
Установить пакеты для работы c Flutter:

```shell
sudo apt-get install curl git git-lfs unzip bzip2
```

Далее следует создать директорию, в которую будет установлен Flutter SDK:

```shell
mkdir -p ~/.local/opt
```

Клонировать репозиторий Flutter с поддержкой платформы ОС Аврора в созданную папку.

`<VERSION>` - тег версии Flutter SDK.

Список тегов можно получить в репозитории [Flutter](https://gitlab.com/omprussia/flutter/flutter/-/tags).

```shell
git clone --branch <VERSION> \
 --depth 1  \
 --config advice.detachedHead=false \
  https://gitlab.com/omprussia/flutter/flutter.git ~/.local/opt/flutter-<VERSION>
```

Добавить `alias`, через который можно будет обратиться к установленному Flutter SDK:

```shell
echo "alias flutter-aurora=$HOME/.local/opt/flutter-<VERSION>/bin/flutter" >> ~/.bashrc
exec bash
```

!!! info

    Установка Flutter SDK, с поддержкой ОС Аврора, производится на локальную систему, так же как и обычный Flutter.

Настроить во Flutter SDK платформу ОС Аврора, для которой будут установлены все необходимые зависимости для работы Flutter:

```shell
flutter-aurora config --enable-aurora
```

Выполнить команду `doctor` и проследовать её инструкциям, чтобы настроить окружение для сборки приложений под ОС Аврора.

```shell
flutter-aurora doctor
```

!!! info

    Flutter `doctor` проверяет таргеты по переменной окружения `PSDK_DIR`.
    Если у вас несколько Platform SDK для проверки определенной версии вы можете изменить переменную окружения выполнив в консоле команду
    `export PSDK_DIR=<путь до Platform SDK>/sdks/aurora_psdk` перед использованием `flutter-aurora doctor`.

## Установка Platform SDK

Для сборки приложений на Flutter используется Platform SDK. 
Установку Platform SDK следует выполнить по [(инструкции)](https://developer.auroraos.ru/doc/software_development/psdk/setup). 
Для работы Platform SDK необходимы права суперпользователя. 
Так как сборка выполняется в консоли, не всегда удобно каждый раз вводить пароль вручную. 
Для решения этой проблемы нужно добавить следующие файлы в директорию `/etc/sudoers.d`, они позволят работать с Platform SDK без ввода пароля суперпользователя.

!!! info

    Вместо `<USERNAME>` необходимо указать имя текущего пользователя.

    Вместо `<PSDK_DIR>` необходимо указать путь к Platfrom SDK.

Файл `/etc/sudoers.d/mer-sdk-chroot`:

```
<USERNAME> ALL=(ALL) NOPASSWD: <PSDK_DIR>
Defaults!<PSDK_DIR> env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"
```

Файл `/etc/sudoers.d/sdk-chroot`:

```
<USERNAME> ALL=(ALL) NOPASSWD: <PSDK_DIR>/sdk-chroot
Defaults!<PSDK_DIR>/sdk-chroot env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"
```

## Установка пакетов для сборки Flutter

Для сборки приложений Flutter требуется пакет [Flutter Embedder](https://gitlab.com/omprussia/flutter/flutter-embedder).
Его нужно установить в один из доступных вам таргетов Platform SDK.

!!! info

    Для Platform SDK 4й и 5й версий пакеты для таргетов отличаются, тоесть для архитектуры `armv7hl` есть пакет для Platform SDK 4й версии и есть пакет для Platform SDK 5й версии.
    Для сборки приложения Flutter на ОС Аврора 5й вресии потребуется Platform SDK 5й версии и аналогично с 4й весрией ОС Аврора/Platform SDK.

Для этого вам нужно клонировать его как выше мы это сделали с Flutter SDK:

`<VERSION>` - тег версии Flutter Embedder.

Список тегов можно получить в репозитории [Flutter Embedder](https://gitlab.com/omprussia/flutter/flutter-embedder/-/tags).

```shell
git clone --branch <VERSION> \
  --depth 1  \
  --config advice.detachedHead=false \
  https://gitlab.com/omprussia/flutter/flutter-embedder.git
```

Для установки зависимостей требуется определить название таргета.

!!! info

    Здесь приведен пример с таргетом архитектуры `armv7hl`, та же логика работает и с другими архитектурами.

Получить полное название таргета можно следующей командой:

```shell
aurora_psdk sdk-assistant list

AuroraOS-4.0.2.89-base
├─AuroraOS-4.0.2.89-base-armv7hl <- <TARGET>
└─AuroraOS-4.0.2.89-base-i486
```

где `<TARGET>` - полное наименование таргета, например, `AuroraOS-4.0.2.89-base-armv7hl`.

Далее, следует перейти в директорию с пакетами:

```shell
cd flutter-embedder
```

Установить пакеты совместимости:

```shell
aurora_psdk sb2 -t <TARGET> \
  -m sdk-install -R zypper --no-gpg-checks in -y dependencies/armv7hl/platform-sdk/*.rpm
```

Установить Flutter Embedder:

```shell
aurora_psdk sb2 -t <TARGET> \
  -m sdk-install -R zypper --no-gpg-checks in -y embedder/armv7hl/*.rpm
```

Очистить снимки таргета:

```shell
aurora_psdk sdk-assistant target remove --snapshots-of <TARGET>
```

!!! info
    
    Начиная с версии Flutter Embedder `3.16.2-1.6.2-1` нужно в путь добавить ключ версии psdk (psdk_4 или psdk_5).
    Пример: `embedder/psdk_4/armv7hl/*.rpm`

## Установка пакетов для работы Flutter

На устройствах до `4.0.2.303` требуется установка дополнительных пакетов от которых зависит работа Flutter.
Пакеты находятся в установленном Flutter SDK по пути`<flutter-embedder>/dependencies/armv7hl/device`.

В следующих версиях эта зависимость будет стоять по умолчанию, но на данный момент ее нужно установить вручную.
Для этого нужно загрузить на телефон пакеты и установить на устройстве с помощью следующей команды:

```
devel-su pkcon install-local *.rpm -y
```
