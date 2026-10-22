cmake_minimum_required(VERSION 3.21)

file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" NOVA_VERSION_FULL LIMIT_COUNT 1)
if(NOT NOVA_VERSION_FULL MATCHES "^([0-9]+\\.[0-9]+\\.[0-9]+)(-[0-9A-Za-z.-]+)?$")
    message(FATAL_ERROR "VERSION inválido: '${NOVA_VERSION_FULL}'")
endif()
set(NOVA_VERSION_NUMERIC "${CMAKE_MATCH_1}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/VERSION")

project(NovaShell VERSION ${NOVA_VERSION_NUMERIC} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(GNUInstallDirs)
include(CTest)
include(cmake/IconLibrary.cmake)

option(NOVA_WERROR "Tratar warnings como errores" OFF)

# Minimum supported Qt for builds lives in packaging/runtime.env. The CI pin
# (tests/requirements-ci.txt) tracks the newest stable release and may move
# ahead on its own: bumping it must not raise what users need to build.
file(STRINGS "${PROJECT_SOURCE_DIR}/packaging/runtime.env" NOVA_QT_REQUIREMENT
    REGEX "^NOVA_MIN_QT=[0-9]+\\.[0-9]+\\.[0-9]+$")
if(NOT NOVA_QT_REQUIREMENT MATCHES "=([0-9]+\\.[0-9]+\\.[0-9]+)$")
    message(FATAL_ERROR "NOVA_MIN_QT missing from packaging/runtime.env")
endif()
set(NOVA_QT_VERSION "${CMAKE_MATCH_1}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${PROJECT_SOURCE_DIR}/packaging/runtime.env")
find_package(Qt6 ${NOVA_QT_VERSION} REQUIRED COMPONENTS Core Network DBus)

add_compile_options(-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wno-sign-conversion)
if(NOVA_WERROR)
    add_compile_options(-Werror)
endif()

add_subdirectory(daemon)

# Prebuilt vector themes: no Node.js dependency on the user's machine.
install(DIRECTORY assets/icons/
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons)
install(FILES packaging/kwin/windows.js DESTINATION ${CMAKE_INSTALL_DATADIR}/novashell/kwin)
install(DIRECTORY packaging/color-schemes/ DESTINATION ${CMAKE_INSTALL_DATADIR}/color-schemes)

# Sesión: fondo claro/oscuro como paquete de Plasma (lo usan escritorio,
# bloqueo y splash) y paquete look-and-feel que solo aporta el splash.
set(NOVA_WALLPAPER_DIR ${CMAKE_INSTALL_DATADIR}/wallpapers/NovaShell)
install(FILES session/wallpaper/metadata.json DESTINATION ${NOVA_WALLPAPER_DIR})
install(FILES assets/wallpapers/nova-light.jpg DESTINATION ${NOVA_WALLPAPER_DIR}/contents/images RENAME 3840x2160.jpg)
install(FILES assets/wallpapers/nova-dark.jpg DESTINATION ${NOVA_WALLPAPER_DIR}/contents/images_dark RENAME 3840x2160.jpg)
set(NOVA_LNF_DIR ${CMAKE_INSTALL_DATADIR}/plasma/look-and-feel/org.knova.novashell)
install(FILES session/lookandfeel/metadata.json DESTINATION ${NOVA_LNF_DIR})
install(FILES session/splash/Splash.qml DESTINATION ${NOVA_LNF_DIR}/contents/splash)
install(DIRECTORY shell/nova/theme/ DESTINATION ${NOVA_LNF_DIR}/contents/splash/theme)
install(FILES assets/brand/nova-mark.svg assets/wallpapers/nova-light.jpg assets/wallpapers/nova-dark.jpg
    DESTINATION ${NOVA_LNF_DIR}/contents/splash/images)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
