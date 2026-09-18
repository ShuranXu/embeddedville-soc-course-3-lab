cmake_minimum_required(VERSION 3.22)
project(embeddedville_soc_course3 C ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXECUTABLE_SUFFIX ".elf")

add_executable(course3_stopwatch
  firmware/startup/startup.S
  firmware/src/drivers.c
  firmware/src/stopwatch.c
)
target_include_directories(course3_stopwatch PRIVATE firmware/include)
target_compile_options(course3_stopwatch PRIVATE -mcpu=cortex-m0 -mthumb -ffreestanding -fdata-sections -ffunction-sections -Wall -Wextra -Werror -Og -g3)
target_link_options(course3_stopwatch PRIVATE -mcpu=cortex-m0 -mthumb -nostartfiles -nostdlib -Wl,--gc-sections -Wl,-Map=${CMAKE_BINARY_DIR}/course3_stopwatch.map -T${CMAKE_CURRENT_SOURCE_DIR}/firmware/linker.ld)
target_link_libraries(course3_stopwatch PRIVATE gcc)

find_program(ARM_OBJCOPY arm-none-eabi-objcopy REQUIRED)
add_custom_command(TARGET course3_stopwatch POST_BUILD
  COMMAND ${ARM_OBJCOPY} -O binary $<TARGET_FILE:course3_stopwatch> ${CMAKE_BINARY_DIR}/course3_stopwatch.bin
  BYPRODUCTS ${CMAKE_BINARY_DIR}/course3_stopwatch.bin
)
