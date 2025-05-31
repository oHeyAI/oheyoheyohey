project(oheyoheyohey)

set(EOSIO_WASM_OLD_BEHAVIOR "Off")
find_package(eosio.cdt)

add_contract( oheyoheyohey oheyoheyohey oheyoheyohey.cpp )
target_include_directories( oheyoheyohey PUBLIC ${CMAKE_SOURCE_DIR}/../include )
#target_ricardian_directory( oheyoheyohey ${CMAKE_SOURCE_DIR}/../ricardian )

add_contract( oheyoheyohey oheyoheyohey_local oheyoheyohey.cpp )
target_include_directories( oheyoheyohey_local PUBLIC ${CMAKE_SOURCE_DIR}/../include )
#target_ricardian_directory( oheyoheyohey_local ${CMAKE_SOURCE_DIR}/../ricardian )
target_compile_definitions( oheyoheyohey_local PUBLIC LOCAL )
