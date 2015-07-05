#!/bin/tcsh -f
set xbinDir="/Applications/Xcode.app/Contents/Developer/usr/bin"

set targetDir_root="./ffmpeg-libs"
set targetDir="${targetDir_root}/armv64"
if (! -d ${targetDir_root} ) mkdir ${targetDir_root}
if (! -d $targetDir ) mkdir $targetDir

rm -f $targetDir/*.a

set headerDir="${targetDir}/headers"
if (! -d $headerDir ) mkdir $headerDir
rm -f $headerDir/*.h

$xbinDir/make clean

./configure \
--cc=/Applications/Xcode.app/Contents/Developer/usr/bin/gcc \
--as='gas-preprocessor.pl /Applications/Xcode.app/Contents/Developer/usr/bin/gcc' \
--nm="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/nm" \
--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.2.sdk \
--target-os=darwin \
--arch=arm \
--cpu=cortex-a8 \
--extra-cflags='-arch armv64 -miphoneos-version-min=4.3 -mdynamic-no-pic' \
--extra-ldflags='-arch armv64 -miphoneos-version-min=4.3 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.2.sdk' \
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

mkdir $headerDir/libavcodec
cp ./libavcodec/*.h $headerDir/libavcodec
mkdir $headerDir/libavdevice
cp ./libavdevice/*.h $headerDir/libavdevice
mkdir $headerDir/libavformat
cp ./libavformat/*.h $headerDir/libavformat
mkdir $headerDir/libavutil
cp ./libavutil/*.h $headerDir/libavutil
mkdir $headerDir/libswscale
cp ./libswscale/*.h $headerDir/libswscale
mkdir $headerDir/libavfilter
cp ./libavfilter/*.h $headerDir/libavfilter
mkdir $headerDir/libpostproc
cp ./libpostproc/*.h $headerDir/libpostproc
mkdir $headerDir/libswresample
cp ./libswresample/*.h $headerDir/libswresample

open "./ffmpeg-libs"