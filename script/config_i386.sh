#!/bin/tcsh -f
#!export PATH=$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin:/usr/bin

set MIN_IOS_VER=5.0
set EXTFLAGS_LD="-miphoneos-version-min=${MIN_IOS_VER}"

set xbinDir="/Applications/Xcode.app/Contents/Developer/usr/bin"

set targetDir_root="./ffmpeg-libs"
set targetDir="${targetDir_root}/i386"
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
--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.2.sdk \
--target-os=darwin \
--arch=i386 \
--cpu=i386 \
--extra-cflags='-arch i386' \
--extra-ldflags='-arch i386 ${EXTFLAGS_LD} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.2.sdk' \
--prefix=compiled/i386 \
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
