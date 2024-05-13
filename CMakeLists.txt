################################################################################
# Setup CPM
################################################################################

set(CPM_DOWNLOAD_ALL ON)
set(CPM_SOURCE_CACHE "${CMAKE_SOURCE_DIR}/cpm-cache")

include(CMake/CPM.cmake)

################################################################################
# Setup vcpkg
################################################################################

CPMAddPackage(
    NAME vcpkg
    DOWNLOAD_ONLY TRUE
    EXCLUDE_FROM_ALL TRUE

    GITHUB_REPOSITORY "microsoft/vcpkg"
    GIT_TAG "2023.08.09"
    GIT_SHALLOW FALSE
)

set(ENV{VCPKG_DEFAULT_BINARY_CACHE} "${CMAKE_SOURCE_DIR}/vcpkg-cache/${VCPKG_TARGET_TRIPLET}")
set(VCPKG_INSTALLED_DIR "${CMAKE_SOURCE_DIR}/vcpkg-installed")
set(VCPKG_APPLOCAL_DEPS OFF)

if(NOT IS_DIRECTORY "$ENV{VCPKG_DEFAULT_BINARY_CACHE}")
    file(MAKE_DIRECTORY "$ENV{VCPKG_DEFAULT_BINARY_CACHE}")
endif()

if(DEFINED ENV{PYENV_ROOT})
    find_program(Python3_EXECUTABLE py REQUIRED)
else()
    find_package(Python3 COMPONENTS Interpreter REQUIRED)
endif()

function(VCPkgAddPackage)
    set(ARG_LIST NAME VERSION)
    cmake_parse_arguments(ARG "" "${ARG_LIST}" "" ${ARGN})

    if(NOT DEFINED ARG_NAME)
        message(FATAL_ERROR "Usage: ${CMAKE_CURRENT_FUNCTION}(NAME <name> [VERSION <version>])")
    endif()

    execute_process(
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMAND ${Python3_EXECUTABLE} _vcpkg/add_package.py ${ARG_NAME} --version ${ARG_VERSION}
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

################################################################################
# Update vcpkg manifest
################################################################################

set(BOOST_INSTALL_VERSION 1.82.0)
VCPkgAddPackage(NAME boost-system     VERSION ${BOOST_INSTALL_VERSION})
VCPkgAddPackage(NAME boost-container  VERSION ${BOOST_INSTALL_VERSION})
VCPkgAddPackage(NAME boost-filesystem VERSION ${BOOST_INSTALL_VERSION})

################################################################################
# Setup vcpkg packages
################################################################################

# _add_executable -> add_executable
function(add_executable)
endfunction()

# __add_executable -> _add_executable
function(_add_executable)
endfunction()

# _add_library -> add_library
function(add_library)
endfunction()

# __add_library -> _add_library
function(_add_library)
endfunction()

include("${vcpkg_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake")

macro(add_applocal_command target_name)
    add_custom_command(
        TARGET "${target_name}" POST_BUILD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMAND ${bash_bin} --login -c "pipenv run python _vcpkg/applocal.py --target-binary $<TARGET_FILE:${target_name}> --installed-dir ${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>$<IF:$<BOOL:${WIN32}>,/bin,/lib>"
        VERBATIM
    )
endmacro()

function(add_executable)
    __add_executable(${ARGV})
    set(target_name "${ARGV0}")

    list(FIND ARGV "IMPORTED" IMPORTED_IDX)
    list(FIND ARGV "ALIAS" ALIAS_IDX)

    if(NOT IMPORTED_IDX EQUAL "-1" OR NOT ALIAS_IDX EQUAL "-1")
        return()
    endif()

    list(FIND ARGV "MACOSX_BUNDLE" MACOSX_BUNDLE_IDX)

    if(APPLE AND MACOSX_BUNDLE_IDX EQUAL "-1")
        return()
    endif()

    add_applocal_command("${target_name}")
endfunction()

function(add_library)
    __add_library(${ARGV})
    set(target_name "${ARGV0}")

    list(FIND ARGV "IMPORTED" IMPORTED_IDX)
    list(FIND ARGV "INTERFACE" INTERFACE_IDX)
    list(FIND ARGV "ALIAS" ALIAS_IDX)

    if(NOT IMPORTED_IDX EQUAL "-1" OR NOT INTERFACE_IDX EQUAL "-1" OR NOT ALIAS_IDX EQUAL "-1")
        return()
    endif()

    get_target_property(TARGET_TYPE "${target_name}" TYPE)

    if(NOT TARGET_TYPE STREQUAL "SHARED_LIBRARY" AND NOT TARGET_TYPE STREQUAL "MODULE_LIBRARY")
        return()
    endif()

    add_applocal_command("${target_name}")
endfunction()

find_package(
    Boost ${BOOST_INSTALL_VERSION} EXACT
    COMPONENTS system
               container
               filesystem
    REQUIRED
)
