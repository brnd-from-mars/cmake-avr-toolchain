###############################################################################
# file: avr.cmake
# author: Brendan Berg
# MIT License
# Copyright (c) 2020 Brendan Berg
###############################################################################


###############################################################################
# find executables
###############################################################################
find_program(AVR_GCC avr-gcc)
find_program(AVR_GXX avr-g++)
find_program(AVR_SIZE avr-size)
find_program(AVR_OBJCOPY avr-objcopy)
find_program(AVR_OBJDUMP avr-objdump)
find_program(AVRDUDE avrdude)

if(NOT AVR_GCC)
    message(FATAL_ERROR "Program avr-gcc not found")
endif(NOT AVR_GCC)
if(NOT AVR_GXX)
    message(FATAL_ERROR "Program avr-g++ not found")
endif(NOT AVR_GXX)
if(NOT AVR_SIZE)
    message(FATAL_ERROR "Program avr-size not found")
endif(NOT AVR_SIZE)
if(NOT AVR_OBJCOPY)
    message(FATAL_ERROR "Program avr-objcopy not found")
endif(NOT AVR_OBJCOPY)
if(NOT AVR_OBJDUMP)
    message(FATAL_ERROR "Program avr-objdump not found")
endif(NOT AVR_OBJDUMP)
if(NOT AVRDUDE)
    message(FATAL_ERROR "Program avrdude not found")
endif(NOT AVRDUDE)

message(STATUS "AVR toolchain executables search done")


###############################################################################
# check upload settings
###############################################################################
if(NOT PROJECT_NAME MATCHES CMAKE_TRY_COMPILE)
    if(NOT AVR_MCU)
        message(FATAL_ERROR "MCU type not specified")
    endif(NOT AVR_MCU)
    if(NOT AVR_PROGRAMMER)
        message(FATAL_ERROR "Programmer not specified")
    endif(NOT AVR_PROGRAMMER)
    if(NOT AVR_PORT)
        message(FATAL_ERROR "Upload port not specified")
    endif(NOT AVR_PORT)
    if(NOT AVR_BAUDRATE)
        st(FATAL_ERROR "Upload baudrate not specified")
    endif(NOT AVR_BAUDRATE)
endif(NOT PROJECT_NAME MATCHES CMAKE_TRY_COMPILE)

if(APPLE)
    set(AVR_SIZE_OPTIONS -B)
else(APPLE)
    set(AVR_SIZE_OPTIONS -C;--mcu=${AVR_MCU})
endif(APPLE)

message(STATUS "AVR upload settings check done")


###############################################################################
# system setups
###############################################################################
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_C_COMPILER ${AVR_GCC})
set(CMAKE_CXX_COMPILER ${AVR_GXX})

message(STATUS "CMake system setup done")


###############################################################################
# check build type
###############################################################################
if(NOT ${PROJECT_NAME} MATCHES CMAKE_TRY_COMPILE)
    if(NOT CMAKE_BUILD_TYPE MATCHES Release)
        message(FATAL_ERROR "Build type doesn't match release")
    endif(NOT CMAKE_BUILD_TYPE MATCHES Release)
endif(NOT ${PROJECT_NAME} MATCHES CMAKE_TRY_COMPILE)

message(STATUS "CMake build type check done")


###############################################################################
# avr_generate_fixed_targets
###############################################################################
function(avr_generate_fixed_targets)
    add_custom_target(
            get_status
            ${AVRDUDE}
                -p${AVR_MCU}
                -c${AVR_PROGRAMMER}
                -P${AVR_PORT}
                "$<$<NOT:$<STREQUAL:${AVR_BAUDRATE},auto>>:-b${AVR_BAUDRATE}>"
                -n
                -v
            COMMENT "Get status from ${AVR_MCU}"
    )
    add_custom_target(
            get_fuses
            ${AVRDUDE}
                -p${AVR_MCU}
                -c${AVR_PROGRAMMER}
                -P${AVR_PORT}
                "$<$<NOT:$<STREQUAL:${AVR_BAUDRATE},auto>>:-b${AVR_BAUDRATE}>"
                "$<$<BOOL:${AVR_LFUSE}>:-Ulfuse:r:-:b>"
                "$<$<BOOL:${AVR_HFUSE}>:-Uhfuse:r:-:b>"
                "$<$<BOOL:${AVR_EFUSE}>:-Uefuse:r:-:b>"
            COMMENT "Get fuses from ${AVR_MCU}"
    )
    add_custom_target(
            set_fuses
            ${AVRDUDE}
                -p${AVR_MCU}
                -c${AVR_PROGRAMMER}
                -P${AVR_PORT}
                "$<$<NOT:$<STREQUAL:${AVR_BAUDRATE},auto>>:-b${AVR_BAUDRATE}>"
                "$<$<BOOL:${AVR_LFUSE}>:-Ulfuse:w:${AVR_LFUSE}:m>"
                "$<$<BOOL:${AVR_HFUSE}>:-Uhfuse:w:${AVR_HFUSE}:m>"
                "$<$<BOOL:${AVR_EFUSE}>:-Uefuse:w:${AVR_EFUSE}:m>"
            COMMENT "Set fuses on ${AVR_MCU}"
    )
    message(STATUS "Adding fixed targets done")
endfunction(avr_generate_fixed_targets)
