# Platform Methods

Flutter Embedder имеет публичные С++ классы с легким доступом к функционалу.
Такими классами являются `PlatformMethods` и `PlatformEvents`.
В них вы найдете методы для получения необходимых данных или подписаться на события Flutter Embedder.
Так же вы найдете методы для управления Flutter Embedder.

## PlatformMethods

```c++
#include <flutter/platform-methods.h>
```

| Метод              | Возвращает           | Описание                                             |
|--------------------|----------------------|------------------------------------------------------|
| GetApplicationID   | `std::string`        | Получение идентификатора приложения.                 |
| GetOrgname         | `std::string`        | Получение Orgname приложения.                        |
| GetAppname         | `std::string`        | Получение Appname приложения.                        |
| GetKeyboardHeight  | `double`             | Получение высоты клавиатуры.                         |
| WindowMaximize     | `void`               | Метод разворачивает свернутое приложение.            |
| WindowMinimize     | `void`               | Метод сворачивает приложение.                        |
| GetEGLDisplay      | `EGLDisplay`         | Получение EGLDisplay для работы с OpenGL.            |
| GetEGLContext      | `EGLContext`         | Получение EGLContext для работы с OpenGL.            |
| GetOrientation     | `DisplayOrientation` | Метод возвращает enum с состоянием поворота дисплея. |
| GetDisplayWidth    | `int32_t`            | Получить ширину дисплея.                             |
| GetDisplayHeight   | `int32_t`            | Получить высоту дисплея.                             |

## PlatformEvents

```c++
#include <flutter/platform-events.h>
```

| Метод                              | Возвращает           | Описание                                             |
|------------------------------------|----------------------|------------------------------------------------------|
| SubscribeKeyboardVisibilityChanged | `bool`               | Подписаться на события открытия/закрытия клавиатуры. |
| SubscribeOrientationChanged        | `DisplayOrientation` | Подписаться на события изменения ориентации.         |

## Platform Types

```c++
#include <flutter/platform-types.h>
```

```c++
// Ориентация дисплея
enum DisplayOrientation {
    kPortrait = 0,
    kLandscape = 90,
    kPortraitFlipped = 180,
    kLandscapeFlipped = 270,
};
```

