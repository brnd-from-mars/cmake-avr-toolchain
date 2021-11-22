# cmake-avr-toolchain
AVR toolchain to be used in e.g. CLion AVR projects



## Example CMakeList.txt file


    cmake_minimum_required(VERSION 3.16)

    set(AVR_MCU atmega328p)
    set(AVR_PROGRAMMER stk500)
    set(AVR_PORT /dev/cu.usbmodemXXXXXX)
    set(AVR_BAUDRATE auto)

    set(AVR_LFUSE 0xff)
    set(AVR_HFUSE 0xdd)
    set(AVR_EFUSE 0xff)
    set(AVR_FREQ 16000000UL)

    project(AVR_project C)

    avr_generate_fixed_targets()

    avr_add_executable(AVR_project main.c)
