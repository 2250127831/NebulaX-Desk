cmake_minimum_required(VERSION 3.16)
project(NebulaX-Desk VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Qml Quick)

qt_add_executable(nebulaX-desk
    src/main.cpp
    src/ClientWorker.cpp
)

target_include_directories(nebulaX-desk PRIVATE include)
target_link_libraries(nebulaX-desk PRIVATE Qt6::Qml Qt6::Quick)
if(WIN32)
    target_link_libraries(nebulaX-desk PRIVATE ws2_32)
endif()

# ── Connectivity test (runs against live server) ──
add_executable(test-connect test/test_connect.cpp src/ClientWorker.cpp)
target_include_directories(test-connect PRIVATE include src)
target_link_libraries(test-connect PRIVATE Qt6::Core)
if(WIN32)
    target_link_libraries(test-connect PRIVATE ws2_32)
endif()

qt_add_qml_module(nebulaX-desk
    URI NebulaX.Desk
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/pages/ConnectionPage.qml
        qml/pages/OrderPage.qml
        qml/pages/MarketPage.qml
        qml/pages/OrderListPage.qml
        qml/components/OrderCard.qml
        qml/components/DepthBar.qml
    NO_RESOURCE_TARGET_PATH
)
