cmake_minimum_required(VERSION 3.5)
project(objcBundle)

set(RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Bundle.app/Contents/MacOS")

add_executable(BundleUnsigned main.mm)
target_compile_options(BundleUnsigned PUBLIC -fobjc-arc -fobjc-weak -fpascal-strings)
target_link_libraries(BundleUnsigned PUBLIC "-framework Cocoa" "-framework Virtualization" "-framework Foundation")
set_target_properties(BundleUnsigned
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Bundle.app/Contents/Resources"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Bundle.app/Contents/Frameworks"
    RUNTIME_OUTPUT_DIRECTORY "${RUNTIME_OUTPUT_DIRECTORY}"
)

add_custom_command(
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/sign.sh ${RUNTIME_OUTPUT_DIRECTORY}/BundleUnsigned ${RUNTIME_OUTPUT_DIRECTORY}/Bundle ${CMAKE_CURRENT_SOURCE_DIR}/virt.entitlements
    DEPENDS BundleUnsigned ${CMAKE_CURRENT_SOURCE_DIR}/virt.entitlements ${CMAKE_CURRENT_SOURCE_DIR}/scripts/sign.sh
    OUTPUT ${RUNTIME_OUTPUT_DIRECTORY}/Bundle)

add_custom_target(Everything ALL DEPENDS ${RUNTIME_OUTPUT_DIRECTORY}/Bundle)