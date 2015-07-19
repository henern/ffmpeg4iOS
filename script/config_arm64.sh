#!/bin/sh -f

# these enviroment variables are required
export ARCH=arm64
export CPU=armv8-a
export BASE_SDK_VER="8.2"
export BASE_SDK_PLAT="iPhoneOS"

tcsh ./config_make.sh
