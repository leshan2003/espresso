cmake_minimum_required(VERSION 3.16)
project(Espresso LANGUAGES CXX)
add_executable(latencytest
    Costmodel/cpp/latencytest.cpp
    Costmodel/cpp/component.cpp)
target_include_directories(latencytest PRIVATE Costmodel/cpp)
target_compile_features(latencytest PRIVATE cxx_std_17)
enable_testing()
add_test(NAME synthetic_events COMMAND latencytest
    ${CMAKE_CURRENT_SOURCE_DIR}/Costmodel/cpp/config/EspressoHarris_config.json
    ${CMAKE_CURRENT_SOURCE_DIR}/input_example/events/synthetic.txt)
set_tests_properties(synthetic_events PROPERTIES
    PASS_REGULAR_EXPRESSION "Total clock cycles: 3890")
