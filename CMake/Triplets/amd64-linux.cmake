set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_CMAKE_SYSTEM_VERSION 1)
set(VCPKG_TARGET_ARCHITECTURE x64)

set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

if("${PORT}" MATCHES "^(gtest.*|tbb.*)")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

cmake_path(GET CMAKE_CURRENT_LIST_FILE FILENAME TOOLCHAIN_FILENAME)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/../Toolchains/${TOOLCHAIN_FILENAME}")

set(VCPKG_FIXUP_ELF_RPATH ON)
