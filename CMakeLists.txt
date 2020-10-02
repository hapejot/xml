# generated file
cmake_minimum_required( VERSION 2.8 )
project(xml)
find_package( LibXml2 )

include_directories( include ${LIBXML2_INCLUDE_DIR} ${ZLIB_INCLUDE} ${ICONV_INCLUDE} )
add_definitions(-DBUILDNO="TEST")

## Install the executable to <install_directory>/bin
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
## Install libraries (if any) to <install_directory>/bin
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin )

file(GLOB WEB xml.w)
# file(GLOB TEX xml.tex)
set(TEX xml.tex)
set(EXE run_xml)
set(PDF xml.pdf)
set(CHG ${CMAKE_HOST_SYSTEM_NAME}.ch)

list(APPEND SOURCES ${CMAKE_CURRENT_BINARY_DIR}/dummy.c  )

add_library(xml SHARED ${SOURCES})
add_executable( ${EXE} xml.c )
target_link_libraries( ${EXE} PUBLIC xml ${LIBXML2_LIBRARY} ${ICONV_LIBRARY} ${ZLIB_LIBRARY} ws2_32 )
# target_link_libraries( ${EXE} xml2 )
install( TARGETS ${EXE} RUNTIME DESTINATION bin )

add_custom_command( OUTPUT ${SOURCES} xml.c
                    COMMAND ctangle ${WEB} ${CHG}
                    DEPENDS ${WEB} )
add_custom_command( OUTPUT ${TEX} 
                    COMMAND cweave ${WEB} ${CHG}
                    DEPENDS ${WEB})
add_custom_command( OUTPUT ${PDF} 
                    COMMAND pdftex ${TEX} 
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/doc
                    COMMAND ${CMAKE_COMMAND} -E copy ${PDF} ${PROJECT_SOURCE_DIR}/doc
                    DEPENDS ${TEX} )
add_custom_target( doc ALL DEPENDS ${PDF} )
