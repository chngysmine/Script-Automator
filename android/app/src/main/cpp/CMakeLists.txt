cmake_minimum_required(VERSION 3.4.1)

add_definitions(-D_GNU_SOURCE -DCONFIG_VERSION="2025-09-13")

# Add QuickJS library source
# Define path to shared native code
set(NATIVE_DIR ../../../../../native)

# Add QuickJS library source
add_library(quickjs STATIC
            ${NATIVE_DIR}/quickjs/quickjs.c
            ${NATIVE_DIR}/quickjs/libregexp.c
            ${NATIVE_DIR}/quickjs/libunicode.c
            ${NATIVE_DIR}/quickjs/cutils.c
            ${NATIVE_DIR}/quickjs/dtoa.c
            ${NATIVE_DIR}/quickjs/quickjs-libc.c)

# Add the wrapper/binding code
add_library(script_engine SHARED
            ${NATIVE_DIR}/quickjs_wrapper.c)

# Include directories
include_directories(${NATIVE_DIR}/quickjs)

# Link libraries
target_link_libraries(script_engine quickjs log)
