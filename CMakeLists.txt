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
file(GLOB CHG ${CMAKE_HOST_SYSTEM_NAME}.ch)
# file(GLOB TEX xml.tex)
set(TEX xml.tex)
set(EXE run_xml)
set(PDF xml.pdf)

if($<STREQUAL:${CMAKE_HOST_SYSTEM_NAME},Windows>)
list(APPEND LIBS ws2_32)
endif()

list(APPEND SOURCES ${CMAKE_CURRENT_BINARY_DIR}/dummy.c  )

add_library(xml SHARED ${SOURCES})
add_executable( ${EXE} xml.c )
target_link_libraries( ${EXE} PUBLIC xml    ${LIBXML2_LIBRARY} 
                                            ${ICONV_LIBRARY} 
                                            ${ZLIB_LIBRARY} ${LIBS} )
install( TARGETS ${EXE} RUNTIME DESTINATION bin )

add_executable( xmlwriter testWriter.c )
target_link_libraries( xmlwriter PUBLIC xml ${LIBXML2_LIBRARY} 
                                            ${ICONV_LIBRARY} 
                                            ${ZLIB_LIBRARY} ${LIBS} )
install( TARGETS xmlwriter RUNTIME DESTINATION bin )

add_executable( io2 io2.c )
target_link_libraries( io2 PUBLIC xml ${LIBXML2_LIBRARY} ${ICONV_LIBRARY} ${ZLIB_LIBRARY} ${LIBS} )
install( TARGETS io2 RUNTIME DESTINATION bin )

add_executable( io1 io1.c )
target_link_libraries( io1 PUBLIC xml ${LIBXML2_LIBRARY} ${ICONV_LIBRARY} ${ZLIB_LIBRARY} ${LIBS} )
install( TARGETS io1 RUNTIME DESTINATION bin )

add_custom_command( OUTPUT ${SOURCES} xml.c io1.c io2.c testWriter.c
                    COMMAND ctangle ${WEB} ${CHG}
                    DEPENDS ${WEB} ${CHG})
add_custom_command( OUTPUT ${TEX} 
                    COMMAND cweave ${WEB} ${CHG}
                    DEPENDS ${WEB} ${CHG})
add_custom_command( OUTPUT ${PDF} 
                    COMMAND pdftex ${TEX} 
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/doc
                    COMMAND ${CMAKE_COMMAND} -E copy ${PDF} ${PROJECT_SOURCE_DIR}/doc
                    DEPENDS ${TEX} )
add_custom_target( doc ALL DEPENDS ${PDF} )
