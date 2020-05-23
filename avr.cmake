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
        message(FATAL_ERROR "Upload baudrate not specified")
    endif(NOT AVR_BAUDRATE)
endif(NOT PROJECT_NAME MATCHES CMAKE_TRY_COMPILE)

if(AVR_BAUDRATE MATCHES auto)
    set(AVR_UPLOAD_OPTIONS -p ${AVR_MCU} -c ${AVR_PROGRAMMER})
else(AVR_BAUDRATE MATCHES auto)
    set(AVR_UPLOAD_OPTIONS -p ${AVR_MCU} -c ${AVR_PROGRAMMER} -b ${AVR_BAUDRATE})
endif(AVR_BAUDRATE MATCHES auto)

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
if(NOT PROJECT_NAME MATCHES CMAKE_TRY_COMPILE)
    if(NOT CMAKE_BUILD_TYPE MATCHES Release)
        message(FATAL_ERROR "Build type doesn't match release")
    endif(NOT CMAKE_BUILD_TYPE MATCHES Release)
endif(NOT PROJECT_NAME MATCHES CMAKE_TRY_COMPILE)

message(STATUS "CMake build type check done")
