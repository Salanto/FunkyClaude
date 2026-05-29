cmake_minimum_required(VERSION 3.21)

project(FunkyClaude VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Multimedia Gui)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(funkyclaude
    src/main.cpp
    src/ClaudeStateMonitor.cpp
    src/ClaudeStateMonitor.h
)

qt_add_qml_module(funkyclaude
    URI FunkyClaude
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

target_link_libraries(funkyclaude PRIVATE
    Qt6::Quick
    Qt6::Multimedia
    Qt6::Gui
)

install(TARGETS funkyclaude
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION bin
)
