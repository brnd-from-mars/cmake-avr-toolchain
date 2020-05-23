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


###############################################################################
# avr_add_executable
###############################################################################
function(avr_add_executable EXEC_NAME)
    if(NOT ARGN)
        message(FATAL_ERROR "Source files not given for ${EXEC_NAME}")
    endif(NOT ARGN)

    set(ELF_FILE ${EXEC_NAME}.elf)
    set(HEX_FILE ${EXEC_NAME}.hex)
    set(LST_FILE ${EXEC_NAME}.lst)
    set(MAP_FILE ${EXEC_NAME}.map)
    set(EEPROM_IMG ${EXEC_NAME}-eeprom.hex)

    add_executable(${ELF_FILE} EXCLUDE_FROM_ALL ${ARGN})
    set_target_properties(
            ${ELF_FILE}
            PROPERTIES
            COMPILE_FLAGS "-mmcu=${AVR_MCU}"
            LINK_FLAGS "-mmcu=${AVR_MCU} -Wl,--gc-sections -mrelax -Wl,-Map,${MAP_FILE}"
    )

    add_custom_command(
            OUTPUT ${HEX_FILE}
            COMMAND
                ${AVR_OBJCOPY} -j .text -j .data -O ihex ${ELF_FILE} ${HEX_FILE}
            COMMAND
                ${AVR_SIZE} ${AVR_SIZE_OPTIONS} ${ELF_FILE}
            DEPENDS ${ELF_FILE}
    )

    add_custom_command(
            OUTPUT ${LST_FILE}
            COMMAND
                ${AVR_OBJDUMP} -d ${ELF_FILE} > ${LST_FILE}
            DEPENDS ${ELF_FILE}
    )

    add_custom_command(
            OUTPUT ${EEPROM_IMG}
            COMMAND
                ${AVR_OBJCOPY} -j .eeprom --set-section-flags=.eeprom=alloc,load --change-section-lma .eeprom=0
                --no-change-warnings -O ihex ${ELF_FILE} ${EEPROM_IMG}
            DEPENDS ${ELF_FILE}
    )

    add_custom_target(
            ${EXEC_NAME}
            ALL
            DEPENDS ${HEX_FILE} ${LST_FILE} ${EEPROM_IMG}
    )
    set_target_properties(
            ${EXEC_NAME}
            PROPERTIES
            OUTPUT_NAME "${ELF_FILE}"
    )
    
    get_directory_property(CLEAN_FILES ADDITIONAL_MAKE_CLEAN_FILES)
    set_directory_properties(
            PROPERTIES
            ADDITIONAL_MAKE_CLEAN_FILES "${MAP_FILE}"
    )

    add_custom_target(
            ${EXEC_NAME}_upload
            ${AVRDUDE}
                -p${AVR_MCU}
                -c${AVR_PROGRAMMER}
                -P${AVR_PORT}
                "$<$<NOT:$<STREQUAL:${AVR_BAUDRATE},auto>>:-b${AVR_BAUDRATE}>"
                -Uflash:w:${HEX_FILE}:i
            DEPENDS ${HEX_FILE}
            COMMENT "Uploading ${HEX_FILE} to ${AVR_MCU} using ${AVR_PROGRAMMER}"
    )

    add_custom_target(
            ${EXEC_NAME}_eeprom_upload
            ${AVRDUDE}
                -p${AVR_MCU}
                -c${AVR_PROGRAMMER}
                -P${AVR_PORT}
                "$<$<NOT:$<STREQUAL:${AVR_BAUDRATE},auto>>:-b${AVR_BAUDRATE}>"
                -Ueeprom:w:${EEPROM_IMG}:i
            DEPENDS ${EEPROM_IMG}
            COMMENT "Uploading ${EEPROM_IMG} to ${AVR_MCU} using ${AVR_PROGRAMMER}"
    )

    add_custom_target(
            ${EXEC_NAME}_disassemble
            ${AVR_OBJDUMP} -h -S ${ELF_FILE} > ${EXEC_NAME}.lst
            DEPENDS ${ELF_FILE}
    )

    message(STATUS "Adding executable ${EXEC_NAME} done")
endfunction(avr_add_executable)


###############################################################################
# avr_add_library
###############################################################################
function(avr_add_library LIB_NAME)
    if(NOT ARGN)
        message(FATAL_ERROR "Source files not given for ${LIB_NAME}")
    endif(NOT ARGN)

    set(LIB_FILE ${LIB_NAME})

    add_library(${LIB_NAME} STATIC ${ARGN})
    set_target_properties(
            ${LIB_FILE}
            PROPERTIES
            COMPILE_FLAGS "-mmcu=${AVR_MCU}"
            OUTPUT_NAME "${LIB_FILE}"
    )

    if(NOT TARGET ${LIB_NAME})
        add_custom_target(
                ${LIB_NAME}
                ALL
                DEPENDS ${LIB_FILE}
        )
        set_target_properties(
                ${LIB_NAME}
                PROPERTIES
                OUTPUT_NAME "${LIB_FILE}"
        )
    endif(NOT TARGET ${LIB_NAME})

    message(STATUS "Adding library ${LIB_NAME} done")
endfunction(avr_add_library)


###############################################################################
# avr_target_link_libraries
###############################################################################
function(avr_target_link_libraries EXEC_TARGET)
    if(NOT ARGN)
        message(FATAL_ERROR "Link targets not given for ${EXEC_NAME}")
    endif(NOT ARGN)

    get_target_property(TARGET_LIST ${EXEC_TARGET} OUTPUT_NAME)

    foreach(TGT ${ARGN})
        if(TARGET ${TGT})
            get_target_property(ARG_NAME ${TGT} OUTPUT_NAME)
            list(APPEND NON_TARGET_LIST ${ARG_NAME})
        else(TARGET ${TGT})
            list(APPEND NON_TARGET_LIST ${TGT})
        endif(TARGET ${TGT})
    endforeach(TGT ${ARGN})

    target_link_libraries(${TARGET_LIST} ${NON_TARGET_LIST})

    message(STATUS "Linking ${EXEC_TARGET} against libraries done")
endfunction(avr_target_link_libraries)


###############################################################################
# avr_target_include_directories
###############################################################################
function(avr_target_include_directories EXEC_TARGET)
    if(NOT ARGN)
        message(FATAL_ERROR "Include directories not given for ${EXEC_NAME}")
    endif()

    get_target_property(TARGET_LIST ${EXEC_TARGET} OUTPUT_NAME)

    target_include_directories(${TARGET_LIST} ${ARGN})

    message(STATUS "Including directories for ${EXEC_TARGET} done")
endfunction(avr_target_include_directories)


###############################################################################
# avr_target_compile_definitions
###############################################################################
function(avr_target_compile_definitions EXEC_TARGET)
    if(NOT ARGN)
        message(FATAL_ERROR "Compile definitions not given for ${EXEC_NAME}")
    endif()

    get_target_property(TARGET_LIST ${EXEC_TARGET} OUTPUT_NAME)

    target_compile_definitions(${TARGET_LIST} ${ARGN})

    message(STATUS "Setting up target compile definitions for ${EXEC_TARGET} done")
endfunction(avr_target_compile_definitions)
