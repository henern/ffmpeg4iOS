#!/bin/sh -f

# these enviroment variables are required
# use x86_64 instead of i386, which is available since iPhone5s
export ARCH=x86_64
export CPU=x86_64
export BASE_SDK_VER="8.2"
export BASE_SDK_PLAT="iPhoneSimulator"

tcsh ./config_make.sh
