## Установка Flutter SDK для разработки под ОС Аврора

В данный момент стабильная работа Flutter SDK проверена на следующих ОС:

- Linux
- Windows WSL2

```shell
$ sudo apt-get install git git-lfs unzip bzip2 curl

$ mkdir -p ~/.local/opt
$ git clone https://gitlab.com/omprussia/flutter/flutter.git ~/.local/opt/flutter

$ echo "alias flutter-aurora=$HOME/.local/opt/flutter/bin/flutter" >> ~/.bashrc
$ exec bash

$ flutter-aurora config --enable-aurora
$ flutter-aurora doctor
```

Следуйте инструкциям команды `flutter-aurora doctor`, чтобы настроить окружение для сборки приложений под ОС Аврора, либо выполните следующие шаги.

### 1. Установка Platform SDK

Установите в вашу систему Platform SDK для сборки приложений под ОС Аврора [(инструкция по установке)](https://developer.auroraos.ru/doc/software_development/psdk/setup).

Для работы Platform SDK необходимы права суперпользователя, и не всегда удобно постоянно вводить пароль суперпользователя при работе с Flutter SDK из-под Platform SDK.

Для решения этой проблемы добавьте следующие файлы в директорию
`/etc/sudoers.d`, которые ползволят работать с Platform SDK без пароля суперпользователя.

> Вместо `<USERNAME>` необходимо указать имя вашего текущего пользователя.

##### /etc/sudoers.d/mer-sdk-chroot

```
<USERNAME>     ALL=(ALL) NOPASSWD: /home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/mer-sdk-chroot
Defaults!/home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/mer-sdk-chroot env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"
```

##### /etc/sudoers.d/sdk-chroot

```
<USERNAME>     ALL=(ALL) NOPASSWD: /home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/sdk-chroot
Defaults!/home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/sdk-chroot env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"
```

Либо перед использованием Flutter SDK единожды выполните любую команду, использующую `sudo`, чтобы в текущей терминальной сессии больше не запрашивался пароль суперпользователя. Например:

```shell
$ sudo echo 'Run doctor' && flutter-aurora doctor
```

### 2. Установка зависимостей в Platform SDK

Установите необходимые пакеты для сборки Flutter приложений в Platform SDK.

```shell
$ cd ~/.local/opt/flutter/bin/cache/artifacts/aurora/arm

# Определите название armv7hl таргета
$ aurora_psdk sdk-assistant list

  AuroraOS-4.0.2.89-base
  ├─AuroraOS-4.0.2.89-base-aarch64
  ├─AuroraOS-4.0.2.89-base-armv7hl <- <TARGET>
  └─AuroraOS-4.0.2.89-base-i486

# Для Аврора 4.0.2 установите пакеты совместимости
# При конфликте хешей игнорируем их, выбрав (i)
$ aurora_psdk sb2 -t <TARGET> -m sdk-install -R zypper in platform-sdk/compatibility/*.rpm

# Установите необходимые пакеты
# При конфликте хешей игнорируем их, выбрав (i)
$ aurora_psdk sb2 -t <TARGET> -m sdk-install -R zypper in platform-sdk/*.rpm

# Очистите снимки armv7hl таргета
$ aurora_psdk sdk-assistant target remove --snapshots-of <TARGET>
```
