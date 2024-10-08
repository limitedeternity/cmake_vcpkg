include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Linux CACHE INTERNAL "")
set(CMAKE_SYSTEM_PROCESSOR x86_64 CACHE INTERNAL "")
set(CMAKE_SYSTEM_VERSION 1 CACHE INTERNAL "")

set(CMAKE_C_COMPILER_TARGET "x86_64-linux-gnu" CACHE INTERNAL "")
set(CMAKE_CXX_COMPILER_TARGET "x86_64-linux-gnu" CACHE INTERNAL "")

function(inherit_from_dotenv DOTENV)
    if(NOT EXISTS "${DOTENV}")
        return()
    endif()

    file(STRINGS "${DOTENV}" ENTRIES)
    foreach(ENTRY IN LISTS ENTRIES)
        if("${ENTRY}" MATCHES "^([^=]+)=(.*)$")
            set(ENV{${CMAKE_MATCH_1}} "${CMAKE_MATCH_2}")
        endif()
    endforeach()
endfunction()

inherit_from_dotenv(/etc/environment)

if(NOT DEFINED CMAKE_GENERATOR)
    set(CMAKE_GENERATOR "Ninja" CACHE INTERNAL "")
endif()

set(CMAKE_C_COMPILER "/usr/bin/clang" CACHE INTERNAL "")
set(CMAKE_CXX_COMPILER "/usr/bin/clang++" CACHE INTERNAL "")

get_property(IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE)

if(NOT IN_TRY_COMPILE)
    set(CMAKE_CXX_FLAGS_INIT "-stdlib=libc++ -fPIC")
    set(CMAKE_CXX_FLAGS_DEBUG_INIT "${CMAKE_CXX_FLAGS_INIT}")
    set(CMAKE_CXX_FLAGS_RELEASE_INIT "${CMAKE_CXX_FLAGS_INIT}")

    set(CMAKE_EXE_LINKER_FLAGS_INIT "-lc++ -lc++abi")
    set(CMAKE_MODULE_LINKER_FLAGS_INIT "-lc++ -lc++abi")
    set(CMAKE_SHARED_LINKER_FLAGS_INIT "-lc++ -lc++abi")
    set(CMAKE_EXE_LINKER_FLAGS_DEBUG_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT}")
    set(CMAKE_MODULE_LINKER_FLAGS_DEBUG_INIT "${CMAKE_MODULE_LINKER_FLAGS_INIT}")
    set(CMAKE_SHARED_LINKER_FLAGS_DEBUG_INIT "${CMAKE_SHARED_LINKER_FLAGS_INIT}")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT}")
    set(CMAKE_MODULE_LINKER_FLAGS_RELEASE_INIT "${CMAKE_MODULE_LINKER_FLAGS_INIT}")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE_INIT "${CMAKE_SHARED_LINKER_FLAGS_INIT}")
endif()

cmake_path(GET CMAKE_CURRENT_LIST_FILE STEM TOOLCHAIN_STEM)
set(VCPKG_OVERLAY_TRIPLETS "${CMAKE_CURRENT_LIST_DIR}/../Triplets")
set(VCPKG_TARGET_TRIPLET ${TOOLCHAIN_STEM})
