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
# environment setup
###############################################################################
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_C_COMPILER ${AVR_GCC})
set(CMAKE_CXX_COMPILER ${AVR_GXX})
