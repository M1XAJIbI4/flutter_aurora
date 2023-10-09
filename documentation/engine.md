# Сборка Flutter Engine

[Flutter Engine](https://github.com/flutter/engine) — это портативная среда выполнения для приложений Flutter. Она реализует основные библиотеки Flutter, включая анимацию и графику, файловый и сетевой ввод-вывод, поддержку специальных возможностей, архитектуру плагинов, а также среду выполнения Dart.

Engine собранный для архитектуры `armv7hl` находится во Flutter SDK по пути:

```agsl
<flutter>/bin/cache/artifacts/engine
```

В следующих режимах:

- debug - `<flutter>/bin/cache/artifacts/engine/aurora-arm`
- profile - `<flutter>/bin/cache/artifacts/engine/aurora-arm-profile`
- release - `<flutter>/bin/cache/artifacts/engine/aurora-arm-release`

Подробнее о режимах Flutter вы можете найти в разделе документации "[Flutter's build modes](https://docs.flutter.dev/testing/build-modes)".

Для самостоятельной сборки вы можете ознакомиться с документацией Flutter Engine - "[Compiling the engine](https://github.com/flutter/flutter/wiki/Compiling-the-engine)". 
Нужно учесть что сборки под платформу `armv7l` нет.
Для сборки можно воспользоваться кросс-компиляций доступной в [Аврора Platform SDK](https://developer.auroraos.ru/doc/software_development/psdk).
Следующий скрипт соберет Flutter Engine `3.13.5`. По нему можно проследить процесс сборки.

```shell
#!/bin/bash

URL_TOOLING="https://sdk-repo.omprussia.ru/sdk/installers/4.0.2/PlatformSDK/4.0.2.249/Aurora_OS-4.0.2.249-base-Aurora_SDK_Tooling-i486.tar.bz2"
URL_TARGET="https://sdk-repo.omprussia.ru/sdk/installers/4.0.2/PlatformSDK/4.0.2.249/Aurora_OS-4.0.2.249-base-Aurora_SDK_Target-armv7hl.tar.bz2"

TAG_VERSION="bd986c5ed20a62dc34b7718c50abc782beae4c33"

NAME_TOOLING=$(basename $URL_TOOLING | sed s/.tar.[a-z]*[0-9]*//g)
NAME_TARGET=$(basename $URL_TARGET | sed s/.tar.[a-z]*[0-9]*//g)

TAR_TOOLING=$(basename $URL_TOOLING | sed s/$NAME_TOOLING.//g)
TAR_TARGET=$(basename $URL_TARGET | sed s/$NAME_TARGET.//g)

clear () {
    rm -rf src
    rm -rf .cipd
    rm -rf .gclien*
    rm -rf depot_tools

    sudo rm -rf "$NAME_TOOLING"
    sudo rm -rf "$NAME_TARGET"
}

##################################### Clear before start

echo "Clear temporary files before start..."

clear

##################################### Install apps

sudo apt install wget clang git curl unzip pkg-config

##################################### Install depot_tools

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=$PWD/depot_tools:$PATH

cat <<EOT >> .gclient
solutions = [
  {
    "managed": False,
    "name": "src/flutter",
    "url": "git@github.com:flutter/engine.git@$TAG_VERSION",
    "custom_deps": {},
    "deps_file": "DEPS",
    "safesync_url": "",
    "custom_vars": {
      "download_android_deps": False,
      "download_windows_deps": False,
    } 
  },
]
EOT

##################################### Run gclient

echo "Run gclient sync..."

gclient sync

##################################### Download tooling

if [ ! -f $(basename $URL_TOOLING) ]; then
    echo "Download tooling..."
	wget $URL_TOOLING
fi

##################################### Extract tooling

echo "Extract tooling..."

if [ $TAR_TOOLING == "tar.bz2" ]; then
    # Create folder
    rm -rf "$NAME_TOOLING" && mkdir "$NAME_TOOLING"
    # Extract
    tar -xjf "$NAME_TOOLING.$TAR_TOOLING" -C "$NAME_TOOLING" 2>/dev/null
else
    # Error format tar
    echo "Error extract tooling! Archive '*.tar.bz2' is expected."
    exit 1
fi

##################################### Download tooling

if [ ! -f $(basename $URL_TARGET) ]; then
    echo "Download target..."
	wget $URL_TARGET
fi

##################################### Extract target

echo "Extract target..."

if [ $TAR_TARGET == "tar.bz2" ]; then
    # Create folder
    rm -rf "$NAME_TARGET" && mkdir "$NAME_TARGET"
    # Extract
    tar -xjf "$NAME_TARGET.$TAR_TARGET" -C "$NAME_TARGET" 2>/dev/null
else
    # Error format tar
    echo "Error extract target! Archive '*.tar.bz2' is expected."
    exit 1
fi

##################################### Create symlinks

echo "Create symlinks..."

mkdir -p ./$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi/bin
mkdir -p ./$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi/lib/gcc

ln -s /bin/clang++ $PWD/$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi/bin/clang++
ln -s /bin/clang $PWD/$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi/bin/clang
ln -s $PWD/$NAME_TOOLING/opt/cross/bin/* $PWD/$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi/bin
ln -s $PWD/$NAME_TOOLING/opt/cross/lib/gcc/armv7hl-meego-linux-gnueabi $PWD/$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi/lib/gcc/armv7hl-meego-linux-gnueabi

##################################### Fixes

## 1. Fix VK_USE_PLATFORM_XCB_KHR

sed -i -e \
's/#ifdef VK_USE_PLATFORM_XCB_KHR/#undef VK_USE_PLATFORM_XCB_KHR\n#ifdef VK_USE_PLATFORM_XCB_KHR/g' \
src/third_party/vulkan-deps/vulkan-headers/src/include/vulkan/vulkan.h

## 2. Fix VK_USE_PLATFORM_WAYLAND_KHR

sed -i -e \
's/#ifdef VK_USE_PLATFORM_WAYLAND_KHR/#undef VK_USE_PLATFORM_WAYLAND_KHR\n#ifdef VK_USE_PLATFORM_WAYLAND_KHR/g' \
src/third_party/vulkan-deps/vulkan-headers/src/include/vulkan/vulkan.h

## 3. Fix warnings as errors

sed -i -e \
's/    "-Werror",  # Warnings as errors./#    "-Werror",  # Warnings as errors./g' \
src/build/config/compiler/BUILD.gn

## 4. Fix BUILD.gn is_clang

sed -i -e \
's/!is_ios \&\& !is_wasm/!is_ios \&\& !is_wasm \&\& false/g' \
src/build/config/compiler/BUILD.gn

## 5. Apply patch https://github.com/flutter/engine/pull/45611

wget https://gitlab.com/omprussia/flutter/flutter/-/raw/aurora-3.13.5/patches/Fix_damage_calculation_%2345611.patch

git apply Fix_damage_calculation_#45611.patch

##################################### Run build

echo "Run build..."

# debug:    --runtime-mode debug --unoptimized

./src/flutter/tools/gn  \
    --runtime-mode debug --unoptimized \
    --target-os linux \
    --linux-cpu arm \
    --arm-float-abi hard \
    --embedder-for-target \
    --disable-desktop-embeddings \
    --no-build-embedder-examples \
    --enable-fontconfig \
    --no-goma \
    --target-toolchain $PWD/$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi \
    --target-sysroot $PWD/$NAME_TARGET \
    --target-triple armv7hl-meego-linux-gnueabi

ninja -C src/out/linux_debug_unopt_arm

# profile:  --runtime-mode profile --no-lto

./src/flutter/tools/gn  \
    --runtime-mode profile --no-lto \
    --target-os linux \
    --linux-cpu arm \
    --arm-float-abi hard \
    --embedder-for-target \
    --disable-desktop-embeddings \
    --no-build-embedder-examples \
    --enable-fontconfig \
    --no-goma \
    --target-toolchain $PWD/$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi \
    --target-sysroot $PWD/$NAME_TARGET \
    --target-triple armv7hl-meego-linux-gnueabi

ninja -C src/out/linux_profile_arm

# release:  --runtime-mode release

./src/flutter/tools/gn  \
    --runtime-mode release \
    --target-os linux \
    --linux-cpu arm \
    --arm-float-abi hard \
    --embedder-for-target \
    --disable-desktop-embeddings \
    --no-build-embedder-examples \
    --enable-fontconfig \
    --no-goma \
    --target-toolchain $PWD/$NAME_TOOLING/opt/cross/armv7hl-meego-linux-gnueabi \
    --target-sysroot $PWD/$NAME_TARGET \
    --target-triple armv7hl-meego-linux-gnueabi

ninja -C src/out/linux_release_arm

##################################### Copy data

echo "Copy data..."

mkdir -p build/aurora-arm

cp ./src/out/linux_debug_unopt_arm/icudtl.dat ./build/aurora-arm
cp ./src/out/linux_debug_unopt_arm/libflutter_engine.so ./build/aurora-arm
cp ./src/out/linux_debug_unopt_arm/clang_x64/gen_snapshot ./build/aurora-arm

mkdir -p build/aurora-arm-profile

cp ./src/out/linux_profile_arm/icudtl.dat ./build/aurora-arm-profile
cp ./src/out/linux_profile_arm/libflutter_engine.so ./build/aurora-arm-profile
cp ./src/out/linux_profile_arm/clang_x64/gen_snapshot ./build/aurora-arm-profile

mkdir -p build/aurora-arm-release

cp ./src/out/linux_release_arm/icudtl.dat ./build/aurora-arm-release
cp ./src/out/linux_release_arm/libflutter_engine.so ./build/aurora-arm-release
cp ./src/out/linux_release_arm/clang_x64/gen_snapshot ./build/aurora-arm-release

##################################### Clear after end

echo "Clear temporary files after end..."

clear
```
