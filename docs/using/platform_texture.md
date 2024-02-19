# Platform Texture

В класс `PluginRegistrar` был добавлен метод, возвращающий `TextureRegistrar`, позволяющий регистрировать Flutter-Texture.
`PluginRegistrar` можно получить при наследовании класса плагина от `PluginInterface` в перегруженном методе `RegisterWithRegistrar`.

```c++
#include <flutter/plugin-interface.h>

class PLUGIN_EXPORT MyPlugin final : public PluginInterface
{
public:
    MyPlugin();
    void RegisterWithRegistrar(PluginRegistrar &registrar) override;
    
private:
    TextureRegistrar m_plugin;
};

void MyPlugin::RegisterWithRegistrar(PluginRegistrar &registrar)
{
    m_plugin = registrar.GetTextureRegistrar();
}
```

TextureRegistrar имеет методы:

* `int64_t RegisterTexture(TextureBufferBuilder)` - Регистрация готовых реализаций OpenGL.
* `int64_t RegisterTexture(TextureBuilder)` - Регистрация пользовательских данных OpenGL.
* `void UnregisterTexture(int64_t)` - Отменяет регистрацию текстуры.
* `void MarkTextureAvailable(int64_t)` - Запрос на обновление данных текстуры.

## TextureBufferBuilder

Метод позволяет использовать готовую реализацию OpenGL в Flutter Embedder.
На данный момент доступна структура `FlutterPixelBuffer` для передачи буфера пикселей:

```c++
typedef struct
{
    std::shared_ptr<uint8_t> buffer;
    size_t width;
    size_t height;
} FlutterPixelBuffer;
```

Пример регистрации:

```c++
int64_t textureId = m_plugin.RegisterTexture(
        [this](size_t, size_t) -> std::optional<BufferVariant> {
            if (/* buffer ok */) {
                return std::make_optional(BufferVariant(
                    FlutterPixelBuffer{/* buffer */, 100, 100}
                ));
            }
            return std::nullopt;
        });
```

## TextureBuilder

Метод позволяет самому реализовать работу с OpenGL.
Пример регистрации:

```c++
int64_t textureId = m_plugin.RegisterTexture(
        [this](size_t, size_t) -> bool {
            /** работа с OpenGL **/
            return true;
        });
```
