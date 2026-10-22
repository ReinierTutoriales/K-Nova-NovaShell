# Núcleo del protocolo: sin sockets, testeable de forma aislada.
add_library(nova_protocol STATIC
    src/Protocol.cpp
    src/Protocol.h
    src/Router.cpp
    src/Router.h
    src/Applications.cpp
    src/Applications.h
    src/Preferences.cpp
    src/Preferences.h
    src/WindowBridge.cpp
    src/WindowBridge.h
    src/DesktopActions.cpp
    src/DesktopActions.h
)
target_include_directories(nova_protocol PUBLIC src)
target_compile_definitions(nova_protocol PUBLIC NOVA_VERSION="${NOVA_VERSION_FULL}")
find_package(PkgConfig REQUIRED)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-unix-2.0>=2.80)
target_link_libraries(nova_protocol PUBLIC Qt6::Core Qt6::DBus PkgConfig::GIO)

# Solo para leer el registro de globals del compositor (compositor.capabilities).
find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND_CLIENT REQUIRED IMPORTED_TARGET wayland-client)

add_library(nova_wayland STATIC
    src/WaylandProbe.cpp
    src/WaylandProbe.h
)
target_include_directories(nova_wayland PUBLIC src)
target_link_libraries(nova_wayland PUBLIC Qt6::Core PRIVATE PkgConfig::WAYLAND_CLIENT)

add_executable(nova-platform
    src/main.cpp
    src/Server.cpp
    src/Server.h
)
target_link_libraries(nova-platform PRIVATE nova_protocol nova_wayland Qt6::Network)

install(TARGETS nova-platform RUNTIME DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
