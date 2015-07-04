#!/bin/tcsh -f
set xbinDir="/Applications/Xcode.app/Contents/Developer/usr/bin"

set targetDir="./ffmpeg-libs/armv7"
if (! -d $targetDir ) mkdir $targetDir

rm -f $targetDir/*.a

$xbinDir/make clean

./configure \
--cc=/Applications/Xcode.app/Contents/Developer/usr/bin/gcc \
--as='gas-preprocessor.pl /Applications/Xcode.app/Contents/Developer/usr/bin/gcc' \
--nm="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/nm" \
--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.2.sdk \
--target-os=darwin \
--arch=arm \
--cpu=cortex-a8 \
--extra-cflags='-arch armv7 -miphoneos-version-min=4.3 -mdynamic-no-pic' \
--extra-ldflags='-arch armv7 -miphoneos-version-min=4.3 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.2.sdk' \
--prefix=compiled/armv7 \
--enable-cross-compile \
--enable-nonfree \
--enable-gpl \
--disable-armv5te \
--disable-swscale-alpha \
--disable-doc \
--disable-ffmpeg \
--disable-ffplay \
--disable-ffprobe \
--disable-ffserver \
--disable-asm \
--disable-debug


$xbinDir/make 

mv ./libavcodec/libavcodec.a $targetDir
mv ./libavdevice/libavdevice.a $targetDir
mv ./libavformat/libavformat.a $targetDir
mv ./libavutil/libavutil.a $targetDir
mv ./libswscale/libswscale.a $targetDir
mv ./libavfilter/libavfilter.a $targetDir
mv ./libpostproc/libpostproc.a $targetDir
mv ./libswresample/libswresample.a $targetDir
