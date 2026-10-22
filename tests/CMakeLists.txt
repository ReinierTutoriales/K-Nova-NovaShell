find_package(Qt6 ${NOVA_QT_VERSION} REQUIRED COMPONENTS Test)

add_executable(tst_protocol tst_protocol.cpp)
target_link_libraries(tst_protocol PRIVATE nova_protocol Qt6::Test)
add_test(NAME protocol COMMAND tst_protocol)
add_executable(tst_desktop tst_desktop.cpp)
target_link_libraries(tst_desktop PRIVATE nova_protocol Qt6::Test)
add_test(NAME desktop COMMAND tst_desktop)

# Prueba de extremo a extremo: arranca el daemon real, habla por el socket
# y compara platform.capabilities con el contrato documentado.
find_package(Python3 COMPONENTS Interpreter)
find_program(NOVA_NODE_EXECUTABLE NAMES node)
if(NOVA_NODE_EXECUTABLE)
    add_test(NAME appearance
        COMMAND ${NOVA_NODE_EXECUTABLE} --test ${CMAKE_CURRENT_SOURCE_DIR}/appearance.test.mjs)
    set_tests_properties(appearance PROPERTIES TIMEOUT 30)
    add_test(NAME desktop_policy COMMAND ${NOVA_NODE_EXECUTABLE} --test ${CMAKE_CURRENT_SOURCE_DIR}/desktop.test.mjs)
endif()
if(Python3_Interpreter_FOUND)
    add_test(NAME icon_library
        COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/icon_library_test.py)
    set_tests_properties(icon_library PROPERTIES TIMEOUT 120)
    add_test(NAME ipc_smoke
        COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/ipc_smoke.py
                $<TARGET_FILE:nova-platform>
                ${PROJECT_SOURCE_DIR}/docs/CONTRATO-IPC-v1.md)
    set_tests_properties(ipc_smoke PROPERTIES SKIP_RETURN_CODE 77 TIMEOUT 30)
endif()
