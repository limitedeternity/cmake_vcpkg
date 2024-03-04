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

if(NOT EXISTS "$ENV{VCPKG_DEFAULT_BINARY_CACHE}")
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

include("${vcpkg_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake")

find_package(
    Boost ${BOOST_INSTALL_VERSION} EXACT
    COMPONENTS system
               container
               filesystem
    REQUIRED
)
