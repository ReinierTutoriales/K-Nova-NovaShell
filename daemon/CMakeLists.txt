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

add_executable(nova-platform
    src/main.cpp
    src/Server.cpp
    src/Server.h
)
target_link_libraries(nova-platform PRIVATE nova_protocol Qt6::Network)

install(TARGETS nova-platform RUNTIME DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
