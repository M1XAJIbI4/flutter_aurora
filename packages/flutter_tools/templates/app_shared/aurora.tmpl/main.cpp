#include <flutter/application.h>
#include "generated_plugin_registrant.h"

int main(int argc, char *argv[]) {
    Application::Initialize(argc, argv);
    Application::SetPixelRatio(1.8);
    RegisterPlugins();
    Application::Launch();
    return 0;
}
