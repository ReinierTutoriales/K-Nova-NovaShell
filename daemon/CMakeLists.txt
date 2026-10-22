# Núcleo del protocolo: sin sockets, testeable de forma aislada.
add_library(nova_protocol STATIC
    src/Protocol.cpp
    src/Protocol.h
    src/Router.cpp
    src/Router.h
)
target_include_directories(nova_protocol PUBLIC src)
target_compile_definitions(nova_protocol PUBLIC NOVA_VERSION="${NOVA_VERSION_FULL}")
target_link_libraries(nova_protocol PUBLIC Qt6::Core)

add_executable(nova-platform
    src/main.cpp
    src/Server.cpp
    src/Server.h
)
target_link_libraries(nova-platform PRIVATE nova_protocol Qt6::Network)

install(TARGETS nova-platform RUNTIME DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
