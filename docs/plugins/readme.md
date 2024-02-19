# Шаблон README.md

Каждый плагин имеет файл README.md с описанием его подключения и основной информацией по нему.
Для стандартизации описания плагина прилагается шаблон, который должен иметь плагин.
Стандартизация упростит как создание плагина, так и его поддержку.

### Параметры

* `PARENT_PLUGIN` - название плагина, который мы имплементируем.
* `AURORA_PLUGIN` - название плагина (`<PARENT_PLUGIN>_aurora`).
* `AURORA_PLUGIN_DESC` - Дополнительное описание плагина.
* `PARENT_PLUGIN_VERSION` - версия родителя имплементируемого плагина.
* `AURORA_PLUGIN_VERSION` - тег версии плагина.
* `AURORA_PLUGIN_PERMISSIONS` - разрешения плагина.
* `AURORA_PLUGIN_DEPENDENCY` - зависимости плагина.
* `AURORA_PLUGIN_LIB_EXCLUDE` - исключить библиотеки "с собой" из валидации.
* `EXAMPLE_DART` - простой пример вызова плагина.

### Шаблон

```markdown
 # <AURORA_PLUGIN>

 The Aurora implementation of [`<PARENT_PLUGIN>`](https://pub.dev/packages/<PARENT_PLUGIN>).

 <AURORA_PLUGIN_DESC>

 ## Usage

 This package is not an _endorsed_ implementation of `<PARENT_PLUGIN>`.
 Therefore, you have to include `<AURORA_PLUGIN>`
 alongside `<PARENT_PLUGIN>` as dependencies in your `pubspec.yaml` file.

 **pubspec.yaml**

 ```yaml
 dependencies:
   <PARENT_PLUGIN>: ^<PARENT_PLUGIN_VERSION>
   <AURORA_PLUGIN>:
     git:
       url: https://gitlab.com/omprussia/flutter/flutter-plugins.git
       ref: <AURORA_PLUGIN_VERSION>
       path: packages/<PARENT_PLUGIN>/<AURORA_PLUGIN>
 ```

 ***main.cpp**

 ```c++
 #include <flutter/application.h>
 #include <flutter/compatibility.h> // <- Add for Qt
 #include "generated_plugin_registrant.h"

 int main(int argc, char *argv[]) {
     Application::Initialize(argc, argv);
     EnableQtCompatibility(); // <- Add for Qt
     RegisterPlugins();
     Application::Launch();
     return 0;
 }
 ```

 ***.desktop**

 ```desktop
 Permissions=<AURORA_PLUGIN_PERMISSIONS>
 ```

 ***.spec**

 ```spec
 %global __requires_exclude ^lib(<AURORA_PLUGIN_LIB_EXCLUDE>)\\.so.*$

 BuildRequires: pkgconfig(<AURORA_PLUGIN_DEPENDENCY>)
 ```

 ***.dart**

 ```dart
 <EXAMPLE_DART>
 ```
```
