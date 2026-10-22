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

# The SDK and portable UI checks share one reviewed stable Qt version.
file(STRINGS "${PROJECT_SOURCE_DIR}/tests/requirements-ci.txt" NOVA_QT_REQUIREMENT
    REGEX "^PySide6-Essentials==[0-9]+\\.[0-9]+\\.[0-9]+$")
if(NOT NOVA_QT_REQUIREMENT MATCHES "==([0-9]+\\.[0-9]+\\.[0-9]+)$")
    message(FATAL_ERROR "Missing pinned stable Qt version")
endif()
set(NOVA_QT_VERSION "${CMAKE_MATCH_1}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${PROJECT_SOURCE_DIR}/tests/requirements-ci.txt")
find_package(Qt6 ${NOVA_QT_VERSION} REQUIRED COMPONENTS Core Network)

add_compile_options(-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wno-sign-conversion)
if(NOVA_WERROR)
    add_compile_options(-Werror)
endif()

add_subdirectory(daemon)

# Prebuilt vector themes: no Node.js dependency on the user's machine.
install(DIRECTORY assets/icons/
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
