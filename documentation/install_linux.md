Defaults!/home/<USERNAME>/AuroraPlatformSDK/sdks/aurora_psdk/sdk-chroot env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"
```

Либо перед использованием Flutter SDK единожды нужно выполнить любую команду, использующую `sudo`, чтобы в текущей терминальной сессии больше не запрашивался пароль суперпользователя:

```shell
sudo echo 'Run doctor' && flutter-aurora doctor
```

## Установка пакетов для сборки Flutter

Для сборки приложения Flutter требуются зависимости, которые нужно добавить в Platform SDK. Необходимые пакеты находятся в клонированном репозитории Flutter по пути: `<flutter>/bin/cache/artifacts/aurora/arm`.
Для сборки приложения Flutter требуются зависимости, которые нужно добавить в Platform SDK. Необходимые пакеты находятся в клонированном репозитории Flutter по пути: `<flutter>/dependencies/arm`.

Для установки зависимостей требуется определить название `armv7hl` таргета. Получить полное название таргета можно следующей командой:


└─AuroraOS-4.0.2.89-base-i486
```

Установить таргет по умолчанию можно с помощью команды:

```shell
aurora_psdk sb2-config -d <TARGET>
```

где `<TARGET>` - полное наименование таргета, например, `AuroraOS-4.0.2.89-base-armv7hl`.

Далее, следует перейти в директорию с пакетами и установить зависимости. При конфликте хешей их нужно проигнорировать, выбрав (`i`):
Далее, следует перейти в директорию с пакетами и установить зависимости:

```shell
cd ~/.local/opt/flutter/bin/cache/artifacts/aurora/arm
cd ~/.local/opt/flutter/dependencies/arm

# Для Аврора 4.0.2 установить пакеты совместимости
aurora_psdk sb2 -t <TARGET> -m sdk-install -R zypper in platform-sdk/compatibility/*.rpm
aurora_psdk sb2 -t <TARGET> -m sdk-install -R zypper --no-gpg-checks in -y platform-sdk/compatibility/*.rpm

# Установить необходимые пакеты
aurora_psdk sb2 -t <TARGET> -m sdk-install -R zypper in platform-sdk/*.rpm
aurora_psdk sb2 -t <TARGET> -m sdk-install -R zypper --no-gpg-checks in -y platform-sdk/*.rpm

# Очистить снимки armv7hl таргета
aurora_psdk sdk-assistant target remove --snapshots-of <TARGET>


## Установка пакетов для работы Flutter

На данный момент ОС Аврора требует также установки дополнительных пакетов от которых зависит работа Flutter. Пакеты находятся в установленном Flutter SDK по пути `<flutter>/bin/cache/artifacts/aurora/arm/device/compatibility`. 
На устройствах до `4.0.2.303` требуется установка дополнительных пакетов от которых зависит работа Flutter. Пакеты находятся в установленном Flutter SDK по пути `<flutter>/dependencies/arm/device/compatibility`. 

> Примечание. На данный момент поддерживается сборка только под архитектуру `armv7hl`, то есть поддержка эмулятора пока недоступна.
> Примечание. На данный момент, для ОС Аврора 4.0.2+, поддерживается сборка только под архитектуру `armv7hl`, то есть поддержка эмулятора пока недоступна. Со следующей версией ОС Аврора 5+ станут доступными архитектуры arm/arm64/x64, где x64 это эмулятор.

В следующих версиях эта зависимость будет стоять по умолчанию, но на данный момент ее нужно установить вручную. Для этого нужно загрузить на телефон пакеты и установить на устройстве с помощью следующей команды:

