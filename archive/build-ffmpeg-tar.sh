#!/bin/sh

VERSION=$1
ARCHS="i386 armv7 arm64"

# working folders
CURRENTPATH=`pwd`
PROJECT_DIR="${CURRENTPATH}/.."
SCRIPTS_DIR="${PROJECT_DIR}/script"
BUILD_SRC_DIR="${PROJECT_DIR}/ffmpeg"

# unzip
FF_TAR_NAME="ffmpeg-${VERSION}.tar.gz"
echo "unzip ${FF_TAR_NAME} to ${BUILD_SRC_DIR} ..."
tar zxf ${FF_TAR_NAME} -C "${BUILD_SRC_DIR}"
cd "${BUILD_SRC_DIR}/ffmpeg-${VERSION}"

# patch
PATCH_DIR="${BUILD_SRC_DIR}/patch/${VERSION}"
if [ -d "${PATCH_DIR}" ];
then
    echo "enable patch-${VERSION} ..."
    cp -Rf "${PATCH_DIR}/" "${BUILD_SRC_DIR}/ffmpeg-${VERSION}"
fi

for ARCH in ${ARCHS}
do
    echo ""
    
    SCRIPT_ARCH_NAME="config_${ARCH}.sh"
    SCRIPT_MAKE_NAME="config_make.sh"
    cp -f "${SCRIPTS_DIR}/${SCRIPT_ARCH_NAME}" .
    cp -f "${SCRIPTS_DIR}/${SCRIPT_MAKE_NAME}" .
    
    # run
    echo "executing ${SCRIPT_ARCH_NAME} ..."
    sh "./${SCRIPT_ARCH_NAME}"
done

