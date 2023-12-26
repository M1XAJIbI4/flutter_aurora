# Установка на Linux

Для настройки рабочего места следует выполнить следующие шаги:

- Установить Flutter SDK
- Установить Platform SDK
- Установка пакетов для сборки Flutter
- Установка пакетов для работы Flutter

## Установка Flutter SDK

Установка будет производиться на систему Ubuntu 22.04. На других системах Linux возможны некоторые незначительные отклонения от документации. Установить пакеты для работы с curl, git и zip:

```shell
sudo apt-get install curl git git-lfs unzip bzip2
```

Далее следует создать директорию, в которую будет установлен Flutter SDK:

```shell
mkdir -p ~/.local/opt
```

Клонировать репозиторий Flutter с поддержкой платформы ОС Аврора в созданную папку и создать `alias`, через который можно будет обратиться к установленному Flutter SDK:

```shell
git clone https://gitlab.com/omprussia/flutter/flutter.git ~/.local/opt/flutter

echo "alias flutter-aurora=$HOME/.local/opt/flutter/bin/flutter" >> ~/.bashrc

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

## Установка Platform SDK

Для сборки приложений на Flutter используется Platform SDK. Установку Platform SDK следует выполнить по [(инструкции)](https://developer.auroraos.ru/doc/software_development/psdk/setup). Для работы Platform SDK необходимы права суперпользователя. Так как сборка выполняется в консоли, не всегда удобно каждый раз вводить пароль вручную. Для решения этой проблемы нужно добавить следующие файлы в директорию `/etc/sudoers.d`, они позволят работать с Platform SDK без ввода пароля суперпользователя.

!!! info

    Вместо `<USERNAME>` необходимо указать имя текущего пользователя.

Файл `/etc/sudoers.d/mer-sdk-chroot`:

```
<USERNAME> ALL=(ALL) NOPASSWD: /home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/mer-sdk-chroot
Defaults!/home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/mer-sdk-chroot env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"
```

Файл `/etc/sudoers.d/sdk-chroot`:

```
<USERNAME> ALL=(ALL) NOPASSWD: /home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/sdk-chroot
Defaults!/home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/sdk-chroot env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"
```

Либо перед использованием Flutter SDK единожды нужно выполнить любую команду, использующую `sudo`, чтобы в текущей терминальной сессии больше не запрашивался пароль суперпользователя:

```shell
sudo echo 'Run doctor' && flutter-aurora doctor
```

## Установка пакетов для сборки Flutter

На устройствах до 4.0.2.303 требуется установка дополнительных пакетов от которых зависит работа Flutter. Необходимые пакеты находятся в клонированном репозитории Flutter по пути: `<flutter>/dependencies/arm`.

Для установки зависимостей требуется определить название `armv7hl` таргета. Получить полное название таргета можно следующей командой:

```shell
aurora_psdk sdk-assistant list

AuroraOS-4.0.2.89-base
├─AuroraOS-4.0.2.89-base-aarch64
├─AuroraOS-4.0.2.89-base-armv7hl <- <TARGET>
└─AuroraOS-4.0.2.89-base-i486
```

Установить таргет по умолчанию можно с помощью команды:

```shell
aurora_psdk sb2-config -d <TARGET>
```

где `<TARGET>` - полное наименование таргета, например, `AuroraOS-4.0.2.89-base-armv7hl`.

Далее, следует перейти в директорию с пакетами и установить зависимости. При конфликте хешей их нужно проигнорировать, выбрав (`i`):

```shell
cd ~/.local/opt/flutter/dependencies/arm

# Для Аврора 4.0.2 установить пакеты совместимости
aurora_psdk sb2 -t <TARGET> -m sdk-install -R zypper in platform-sdk/compatibility/*.rpm

# Установить необходимые пакеты
aurora_psdk sb2 -t <TARGET> -m sdk-install -R zypper in platform-sdk/*.rpm

# Очистить снимки armv7hl таргета
aurora_psdk sdk-assistant target remove --snapshots-of <TARGET>
```

## Установка пакетов для работы Flutter

На данный момент ОС Аврора требует также установки дополнительных пакетов от которых зависит работа Flutter. Пакеты находятся в установленном Flutter SDK по пути `<flutter>/dependencies/arm/device/compatibility`. 

!!! info

    На данный момент поддерживается сборка только под архитектуру `armv7hl`, то есть поддержка эмулятора пока недоступна.

В следующих версиях эта зависимость будет стоять по умолчанию, но на данный момент ее нужно установить вручную. Для этого нужно загрузить на телефон пакеты и установить на устройстве с помощью следующей команды:

```
devel-su pkcon install-local *.rpm -y
```
