# ===============================================
# Compile afl-fuzz & frida_mode for Android
# Original author: Eric Le Guevel (2023-03-28)
# Redacted by: KernelKrise (2024-04-16)
# Cleaned up: 2026-04-07
# ===============================================
cmake_minimum_required(VERSION 3.13)
project(AFLppAndroid C CXX)

add_compile_options(
    -Wno-pointer-sign
    -Wno-pointer-arith
    -Wno-sign-compare
    -Wno-unused-parameter
    -Wno-unused-function
    -Wno-format
    -Wno-user-defined-warnings
    -Wno-macro-redefined
    -Wno-deprecated
)

# ========
# afl-fuzz
# ========
file(GLOB afl-fuzz-c CONFIGURE_DEPENDS src/afl-fuzz*.c)
add_executable(
    afl-fuzz
    ${afl-fuzz-c}
    src/afl-common.c
    src/afl-forkserver.c
    src/afl-sharedmem.c
    src/afl-performance.c
)
target_include_directories(afl-fuzz PRIVATE ${CMAKE_SOURCE_DIR}/include)
target_compile_definitions(
    afl-fuzz
    PRIVATE
        DOC_PATH="/usr/local/share/doc/afl"
        BIN_PATH="/usr/local/bin"
        AFL_PATH="/usr/local/lib/afl"
        _FORTIFY_SOURCE=2
)
target_compile_options(afl-fuzz PRIVATE -O2)
set_target_properties(afl-fuzz PROPERTIES POSITION_INDEPENDENT_CODE ON)

# ==========
# frida_mode
# ==========

# Resolve FRIDA_VERSION: -D flag > env var > error
if(NOT FRIDA_VERSION)
    if(DEFINED ENV{FRIDA_VERSION})
        set(FRIDA_VERSION "$ENV{FRIDA_VERSION}")
    else()
        message(FATAL_ERROR
            "FRIDA_VERSION is not set. "
            "Provide it via environment variable (FRIDA_VERSION=...) "
            "or -DFRIDA_VERSION=...")
    endif()
endif()
message(STATUS "Frida version: ${FRIDA_VERSION}")

# Map ANDROID_ABI -> frida gumjs arch name
if(NOT ANDROID_ABI)
    message(FATAL_ERROR
        "ANDROID_ABI is not set. "
        "Provide it via -DANDROID_ABI=... "
        "(supported: arm64-v8a, armeabi-v7a, x86_64, x86)")
endif()

if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(FRIDA_GUMJS_ARCH "arm64")
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(FRIDA_GUMJS_ARCH "arm")
elseif(ANDROID_ABI STREQUAL "x86_64")
    set(FRIDA_GUMJS_ARCH "x86_64")
elseif(ANDROID_ABI STREQUAL "x86")
    set(FRIDA_GUMJS_ARCH "x86")
else()
    message(FATAL_ERROR
        "Unsupported ANDROID_ABI: '${ANDROID_ABI}'. "
        "Supported values: arm64-v8a, armeabi-v7a, x86_64, x86")
endif()
message(STATUS "Android ABI: ${ANDROID_ABI} -> frida arch: ${FRIDA_GUMJS_ARCH}")

set(FRIDA_REPO_URL "https://github.com/frida/frida/releases/download")
set(FRIDA_GDK_TARBALL_NAME
    "frida-gumjs-devkit-${FRIDA_VERSION}-android-${FRIDA_GUMJS_ARCH}.tar.xz")
set(FRIDA_GDK_TARBALL "${CMAKE_BINARY_DIR}/${FRIDA_GDK_TARBALL_NAME}")
set(FRIDA_GDK_URL "${FRIDA_REPO_URL}/${FRIDA_VERSION}/${FRIDA_GDK_TARBALL_NAME}")
set(FRIDA_DIR "${CMAKE_BINARY_DIR}/frida-${FRIDA_VERSION}-${FRIDA_GUMJS_ARCH}")

if(NOT EXISTS ${FRIDA_DIR})
    if(NOT EXISTS ${FRIDA_GDK_TARBALL})
        message(STATUS "Downloading ${FRIDA_GDK_URL}")
        file(DOWNLOAD ${FRIDA_GDK_URL} ${FRIDA_GDK_TARBALL}
             SHOW_PROGRESS
             STATUS dl_status)
        list(GET dl_status 0 dl_code)
        if(NOT dl_code EQUAL 0)
            file(REMOVE ${FRIDA_GDK_TARBALL})
            list(GET dl_status 1 dl_msg)
            message(FATAL_ERROR
                "Failed to download frida devkit (${dl_code}): ${dl_msg}\n"
                "URL: ${FRIDA_GDK_URL}")
        endif()
    endif()
    file(MAKE_DIRECTORY ${FRIDA_DIR})
    file(ARCHIVE_EXTRACT INPUT ${FRIDA_GDK_TARBALL} DESTINATION ${FRIDA_DIR})
endif()

# Generate api.c from api.js
set(API_JS "${CMAKE_SOURCE_DIR}/frida_mode/src/js/api.js")
set(API_C  "${CMAKE_BINARY_DIR}/api.c")

find_program(XXD_EXECUTABLE xxd REQUIRED)
find_program(STAT_EXECUTABLE stat REQUIRED)

add_custom_command(
    OUTPUT ${API_C}
    COMMAND bash -c
        "echo 'unsigned char api_js[] = {' > ${API_C} && \
         ${XXD_EXECUTABLE} -p -c 12 ${API_JS} \
            | sed -e 's/\\([0-9a-f]\\{2\\}\\)/0x\\1, /g' \
            | sed -e 's/^/  /' >> ${API_C} && \
         echo '};' >> ${API_C} && \
         echo \"unsigned int api_js_len = $(${STAT_EXECUTABLE} --printf='%s' ${API_JS});\" >> ${API_C}"
    DEPENDS ${API_JS}
    COMMENT "Generating api.c from api.js"
    VERBATIM
)

# Build afl-frida-trace
file(GLOB_RECURSE FRIDA_MODE_SRCS CONFIGURE_DEPENDS frida_mode/src/*.c)
add_library(
    afl-frida-trace SHARED
    ${FRIDA_MODE_SRCS}
    ${API_C}
    ${CMAKE_SOURCE_DIR}/instrumentation/afl-compiler-rt.o.c
    ${CMAKE_SOURCE_DIR}/src/afl-performance.c
)
target_include_directories(
    afl-frida-trace PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/frida_mode/include
    ${FRIDA_DIR}
)
target_compile_definitions(afl-frida-trace PRIVATE ANDROID)
target_link_directories(afl-frida-trace PRIVATE ${FRIDA_DIR})
target_link_libraries(afl-frida-trace PRIVATE frida-gumjs log dl)
target_link_options(
    afl-frida-trace PRIVATE
    -static-libstdc++
    -Wl,-z,noexecstack
    -Wl,--gc-sections
    -Wl,--exclude-libs,ALL
    -Wl,--version-script=${CMAKE_SOURCE_DIR}/frida_mode/frida.map
)
set_target_properties(afl-frida-trace PROPERTIES
    PREFIX ""
    LINKER_LANGUAGE CXX
    POSITION_INDEPENDENT_CODE ON
)