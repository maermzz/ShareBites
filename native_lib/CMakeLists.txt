cmake_minimum_required(VERSION 3.10)
project(dsa_backend) # This changes the output name

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

# This creates dsa_backend.dll
add_library(dsa_backend SHARED native_lib.cpp)

# AUTOMATION: This copies the DLL to your flutter build folder automatically
add_custom_command(TARGET dsa_backend POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_CURRENT_BINARY_DIR}/Release/dsa_backend.dll
        ${CMAKE_SOURCE_DIR}/../build/windows/x64/runner/Debug/dsa_backend.dll
)