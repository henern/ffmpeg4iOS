#!/bin/tcsh -f
#!export PATH=$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin:/usr/bin

#use x86_64 instead of i386, which is available since iPhone5s
set ARCH=x86_64

#base on iOS8.2 SDK
set BASE_SDK_VER="8.2"
set BASE_SDK_PLAT="iPhoneSimulator"
set SYS_ROOT="/Applications/Xcode.app/Contents/Developer/Platforms/${BASE_SDK_PLAT}.platform/Developer/SDKs/${BASE_SDK_PLAT}${BASE_SDK_VER}.sdk"

#at least iOS5.0
set MIN_IOS_VER=5.0
set EXTFLAGS_LD="-miphoneos-version-min=${MIN_IOS_VER}"

set xbinDir="/Applications/Xcode.app/Contents/Developer/usr/bin"

set targetDir_root="./ffmpeg-libs"
set targetDir="${targetDir_root}/${ARCH}"
if (! -d ${targetDir_root} ) mkdir ${targetDir_root}
if (! -d $targetDir ) mkdir $targetDir

rm -f $targetDir/*.a

set headerDir="${targetDir}/headers"
if (! -d $headerDir ) mkdir $headerDir
rm -f $headerDir/*.h

$xbinDir/make clean

#./configure --arch=i386 --extra-cflags='-arch i386' --extra-ldflags='-arch i386'  --disable-encoders --disable-debug --disable-mmx

./configure \
--cc=/Applications/Xcode.app/Contents/Developer/usr/bin/gcc \
--as='/usr/local/bin/gas-preprocessor.pl /Applications/Xcode.app/Contents/Developer/usr/bin/gcc' \
--sysroot="${SYS_ROOT}" \
--target-os=darwin \
--arch="${ARCH}" \
--cpu="${ARCH}" \
--extra-cflags="-arch ${ARCH}" \
--extra-ldflags="-arch ${ARCH} ${EXTFLAGS_LD} -isysroot ${SYS_ROOT}" \
--prefix="compiled/${ARCH}" \
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

$xbinDir/make && $xbinDir/make install

mv ./libavcodec/libavcodec.a $targetDir/libavcodec-${ARCH}.a
mv ./libavdevice/libavdevice.a $targetDir/libavdevice-${ARCH}.a
mv ./libavformat/libavformat.a $targetDir/libavformat-${ARCH}.a
mv ./libavutil/libavutil.a $targetDir/libavutil-${ARCH}.a
mv ./libswscale/libswscale.a $targetDir/libswscale-${ARCH}.a
mv ./libavfilter/libavfilter.a $targetDir/libavfilter-${ARCH}.a
mv ./libpostproc/libpostproc.a $targetDir/libpostproc-${ARCH}.a
mv ./libswresample/libswresample.a $targetDir/libswresample-${ARCH}.a

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
