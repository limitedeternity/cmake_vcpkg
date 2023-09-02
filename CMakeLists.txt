################################################################################
# Setup CPM
################################################################################

set(CPM_SOURCE_CACHE "${CMAKE_SOURCE_DIR}/cpm-cache")
set(CPM_USE_NAMED_CACHE_DIRECTORIES ON)

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

set(VCPKG_MANIFEST_DIR "${CMAKE_SOURCE_DIR}")
set(VCPKG_INSTALLED_DIR "${CMAKE_SOURCE_DIR}/vcpkg-installed")

find_package(Python3 COMPONENTS Interpreter REQUIRED)

macro(VCPkgAddPackage NAME VERSION)
    execute_process(
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMAND ${Python3_EXECUTABLE} _vcpkg/add_package.py ${NAME} --version ${VERSION}
    )
endmacro()

################################################################################
# Update vcpkg manifest
################################################################################

VCPkgAddPackage(Boost 1.82.0)

################################################################################
# Setup vcpkg packages
################################################################################

include("${vcpkg_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake")

set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_LIBS OFF)
set(Boost_USE_STATIC_RUNTIME OFF)

find_package(
    Boost 1.82.0 EXACT
    COMPONENTS system filesystem container
    REQUIRED
)
