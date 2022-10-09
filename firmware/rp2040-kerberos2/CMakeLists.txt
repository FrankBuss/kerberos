cmake_minimum_required(VERSION 3.20.0)
set(BOARD rpi_pico)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(rp2040-kerberos2)

target_sources(app PRIVATE src/main.c)
