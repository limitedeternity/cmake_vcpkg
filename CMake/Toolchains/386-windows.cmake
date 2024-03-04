include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Windows CACHE INTERNAL "")
set(CMAKE_SYSTEM_PROCESSOR X86 CACHE INTERNAL "")
set(CMAKE_SYSTEM_VERSION 6.1 CACHE INTERNAL "")

function(msvc_inherit_from_vcvars ARCH)
    execute_process(
        COMMAND cmd /c "if defined DevEnvDir (exit 1)"
        RESULT_VARIABLE CMD_RESULT
    )

    if(NOT ${CMD_RESULT} EQUAL 0)
        return()
    endif()

    cmake_host_system_information(RESULT VS_DIR QUERY VS_17_DIR)
    set(VCVARSALL_PATH "${VS_DIR}/VC/Auxiliary/Build/vcvarsall.bat")

    if(NOT EXISTS "${VCVARSALL_PATH}")
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: no vcvarsall.bat detected")
    endif()

    execute_process(
        COMMAND cmd /c echo {SET0} && set && echo {/SET0} && "${VCVARSALL_PATH}" ${ARCH} && echo {SET1} && set && echo {/SET1}
        OUTPUT_VARIABLE CMD_OUTPUT
        RESULT_VARIABLE CMD_RESULT
    )

    if(NOT ${CMD_RESULT} EQUAL 0)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: environment setup returned '${CMD_RESULT}'")
    endif()

    set(REST "${CMD_OUTPUT}")
    string(FIND "${REST}" "{SET0}" BEG)
    string(SUBSTRING "${REST}" ${BEG} -1 REST)
    string(FIND "${REST}" "{/SET0}" END)
    string(SUBSTRING "${REST}" 0 ${END} SET0)
    string(SUBSTRING "${SET0}" 6 -1 SET0)
    string(FIND "${REST}" "{SET1}" BEG)
    string(SUBSTRING "${REST}" ${BEG} -1 REST)
    string(FIND "${REST}" "{/SET1}" END)
    string(SUBSTRING "${REST}" 0 ${END} SET1)
    string(SUBSTRING "${SET1}" 6 -1 SET1)
    string(REGEX MATCHALL "\n[0-9a-zA-Z_]*" SET0_VARS "${SET0}")
    list(TRANSFORM SET0_VARS STRIP)
    string(REGEX MATCHALL "\n[0-9a-zA-Z_]*" SET1_VARS "${SET1}")
    list(TRANSFORM SET1_VARS STRIP)

    function(_extract_from_set_command INPUT VARNAME OUTVAR_NAME)
        set(R "${INPUT}")
        string(FIND "${R}" "\n${VARNAME}=" B)

        if(B EQUAL -1)
            set(${OUTVAR_NAME} "" PARENT_SCOPE)
            return()
        endif()

        string(SUBSTRING "${R}" ${B} -1 R)
        string(SUBSTRING "${R}" 1 -1 R)
        string(FIND "${R}" "\n" E)
        string(SUBSTRING "${R}" 0 ${E} OUT_TEMP)
        string(LENGTH "${VARNAME}=" VARNAME_LEN)
        string(SUBSTRING "${OUT_TEMP}" ${VARNAME_LEN} -1 OUT_TEMP)
        set(${OUTVAR_NAME} "${OUT_TEMP}" PARENT_SCOPE)
    endfunction()

    set(CHANGED_VARS)

    foreach(V ${SET1_VARS})
        _extract_from_set_command("${SET0}" ${V} V0)
        _extract_from_set_command("${SET1}" ${V} V1)

        if(NOT "${V0}" STREQUAL "${V1}")
            list(APPEND CHANGED_VARS ${V})
            set(MSVC_ENV_${V} "${V1}")
        endif()
    endforeach()

    set(MSVC_ENV_VAR_NAMES ${CHANGED_VARS})

    foreach(V ${MSVC_ENV_VAR_NAMES})
        if(NOT "$ENV{${V}}" STREQUAL "${MSVC_ENV_${V}}")
            set(ENV{${V}} "${MSVC_ENV_${V}}")
        endif()
    endforeach()
endfunction()

if(NOT DEFINED CMAKE_GENERATOR)
    set(CMAKE_GENERATOR "Visual Studio 17 2022" CACHE INTERNAL "")
endif()

if("${CMAKE_GENERATOR}" STREQUAL "Visual Studio 17 2022")
    if("${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "AMD64")
        msvc_inherit_from_vcvars(x64_x86)
    else()
        msvc_inherit_from_vcvars(x86)
    endif()

    set(CMAKE_GENERATOR_TOOLSET ClangCL,host=x86 CACHE INTERNAL "")
    set(CMAKE_GENERATOR_PLATFORM Win32 CACHE INTERNAL "")
endif()

cmake_path(GET CMAKE_CURRENT_LIST_FILE STEM TOOLCHAIN_STEM)
set(VCPKG_OVERLAY_TRIPLETS "${CMAKE_CURRENT_LIST_DIR}/../Triplets")
set(VCPKG_TARGET_TRIPLET ${TOOLCHAIN_STEM})
