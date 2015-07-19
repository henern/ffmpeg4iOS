#!/bin/sh -f

# these enviroment variables are required
export ARCH=armv7
export CPU=cortex-a8
export BASE_SDK_VER="8.2"
export BASE_SDK_PLAT="iPhoneOS"

tcsh ./config_make.sh

