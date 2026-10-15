cmake_minimum_required(VERSION 3.24)

project(HadesTools VERSION 0.2.6 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Network Qml Quick)
qt_standard_project_setup(REQUIRES 6.8)

set(MD3_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/material-components-qml")
if(NOT EXISTS "${MD3_SOURCE_DIR}/src/Core/CMakeLists.txt")
    message(FATAL_ERROR "material-components-qml source is missing")
endif()
add_subdirectory("${MD3_SOURCE_DIR}/src/Core" md3Core_build)

qt_add_executable(HadesTools
    MANUAL_FINALIZATION
    src/app/main.cpp
    src/app/AppController.cpp
    src/app/AppController.h
    src/app/WindowAppearance.cpp
    src/app/WindowAppearance.h
    src/backend/HadesToolsClient.cpp
    src/backend/HadesToolsClient.h
    src/backend/CatalogModel.cpp
    src/backend/CatalogModel.h
)
set_target_properties(HadesTools PROPERTIES WIN32_EXECUTABLE TRUE)

set_source_files_properties(src/qml/UiStyle.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(HadesTools
    URI hades.Tools
    VERSION 1.0
    QML_FILES
        src/qml/Main.qml
        src/qml/WindowTitleBar.qml
        src/qml/WindowResizeHandles.qml
        src/qml/UiStyle.qml
        src/qml/AppText.qml
        src/qml/SvgIcon.qml
        src/qml/pages/OverviewPage.qml
        src/qml/pages/FunctionsPage.qml
        src/qml/pages/PlayerStatePage.qml
        src/qml/pages/SectionCard.qml
        src/qml/pages/MetricCard.qml
        src/qml/pages/AttributeEditor.qml
        src/qml/pages/ResourcesPage.qml
        src/qml/pages/CatalogPage.qml
        src/qml/pages/CatalogSearch.qml
        src/qml/pages/LiveNumberField.qml
        src/qml/pages/LogsPage.qml
        src/qml/pages/AboutPage.qml
        src/qml/pages/SettingsPage.qml
        src/qml/pages/ThemeChoice.qml
    RESOURCES
        src/qml/assets/circle-alert.svg
        src/qml/assets/languages.svg
)

target_include_directories(HadesTools PRIVATE src/app src/backend)
target_link_libraries(HadesTools PRIVATE Qt6::Core Qt6::Gui Qt6::Network Qt6::Qml Qt6::Quick
    "$<LINK_LIBRARY:WHOLE_ARCHIVE,md3Core>")
if(WIN32)
    target_link_libraries(HadesTools PRIVATE dwmapi)
endif()

qt_import_qml_plugins(HadesTools)
qt_finalize_executable(HadesTools)

add_custom_command(TARGET HadesTools POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/translations"
        "$<TARGET_FILE_DIR:HadesTools>/translations"
)

option(HADES_TOOLS_BUILD_CHECKS "Build catalog verification executable" OFF)
if(HADES_TOOLS_BUILD_CHECKS)
    qt_add_executable(HadesToolsCatalogCheck
        tools/catalog_check.cpp src/backend/CatalogModel.cpp src/backend/CatalogModel.h)
    set_target_properties(HadesToolsCatalogCheck PROPERTIES WIN32_EXECUTABLE FALSE)
    target_include_directories(HadesToolsCatalogCheck PRIVATE src/backend)
    target_link_libraries(HadesToolsCatalogCheck PRIVATE Qt6::Core Qt6::Gui)
endif()
