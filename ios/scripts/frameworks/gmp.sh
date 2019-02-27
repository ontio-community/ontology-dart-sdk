#!/usr/bin/env bash

GMP_VER="6.1.2"

ARCHS="x86_64 armv7 arm64"

DIR="$(cd "$(dirname "$0")" && pwd)"

BUILD_DIR=${DIR}/build/gmp

GMP_TAR_BASE_NAME=gmp-${GMP_VER}
GMP_TAR_FILE_NAME=${GMP_TAR_BASE_NAME}.tar.bz2
GMP_TAR_FILE=${BUILD_DIR}/${GMP_TAR_FILE_NAME}
GMP_TAR_X_DIR=${BUILD_DIR}/${GMP_TAR_BASE_NAME}

OUT_DIR=${BUILD_DIR}/out

LOG=${BUILD_DIR}/gmp.log

FMK_BASE_NAME=gmp
FMK_FILE_NAME=gmp.framework
FMK_FILE=${BUILD_DIR}/${FMK_FILE_NAME}
FMK_DST_DIR=${DIR}/../../Frameworks
FMK_DST=${FMK_DST_DIR}/${FMK_FILE_NAME}

mkd() {
  dir=$1
  if [ -d "{$dir}" ]; then
    return
  fi
  mkdir -p $dir
}

make_build_dir() {
  mkd $BUILD_DIR
  echo "Build into directory: ${BUILD_DIR}"
}

download_tar() {
  if [ ! -d ${GMP_TAR_X_DIR} ]; then
    if [ ! -f ${GMP_TAR_FILE} ]; then
      echo "Downloading GMP ${GMP_VER}"
      curl -L https://gmplib.org/download/gmp/${GMP_TAR_FILE_NAME} > ${GMP_TAR_FILE}
    fi
    tar jxf ${GMP_TAR_FILE} -C ${BUILD_DIR}
    chmod u+x ${GMP_TAR_X_DIR}/configure
  else
    echo "Using ${GMP_TAR_FILE}"
  fi
}

skip_if_dup() {
  if [ -d "${FMK_DST}" ]; then 
    exit 0
  fi
}

build_for() {
  local arch=$1
  local sdk=""
  local bitcode=""
  local prefix="${OUT_DIR}/${arch}"
  local host=""

  if [ -d "${prefix}" ]; then
    return
  fi

  if [ "${arch}" == "x86_64" ]; then
    sdk="iphonesimulator"
  elif [[ "${arch}" == "armv7" || "${arch}" == "armv7s" ]]; then
    sdk="iphoneos"
    bitcode="-fembed-bitcode"
    host="--host=armv7-apple-darwin"
  elif [ "${arch}" == "arm64" ]; then
    sdk="iphoneos"
    bitcode="-fembed-bitcode"
    host="--host=aarch64-apple-darwin"
  fi

  local CC="$(xcrun --sdk ${sdk} --find clang) -isysroot $(xcrun --sdk ${sdk} --show-sdk-path) ${bitcode} -fno-common -O2 -arch ${arch}"

  cd ${GMP_TAR_X_DIR}

  make clean
  make distclean

  env -i ./configure --prefix="${prefix}" ${host} --disable-assembly --enable-static --disable-shared
  env -i make CC="${CC}" -j `sysctl -n hw.logicalcpu_max`
  make install
}

build() {
  echo "Archs: ${ARCHS}"
  echo -e "Open below command in a new tab to see building log:\n\n  tail -f ${LOG}\n"
  for arch in ${ARCHS}
  do
    echo "Building for: ${arch}"
    build_for $arch >> "${LOG}" 2>&1
  done
}

create_shim() {
  local code=$(cat<<CODE
#ifndef GMPHelper_h
#define GMPHelper_h

#include <gmp/gmp.h>

#endif
CODE
)

  echo "${code}" > $FMK_FILE/shim.h
}

create_modulemap() {
  mkd "${FMK_FILE}/Modules"

  local code=$(cat<<CODE
module GMP {
  header "shim.h"
  export *
}
CODE
)

  echo "${code}" > ${FMK_FILE}/Modules/module.modulemap
}

create_framework() {
  echo "Creating ${FMK_FILE_NAME}..."
  rm -rf ${FMK_FILE}
  mkd "${FMK_FILE}/Headers"
  mkd "${OUT_DIR}/lib"

  local libgmp=""
  for arch in ${ARCHS}
  do
    libgmp="${libgmp} ${OUT_DIR}/${arch}/lib/libgmp.a"
  done

  lipo ${libgmp} -create -output "${OUT_DIR}/lib/libgmp.a"

  libtool -no_warning_for_no_symbols -static -o \
    $FMK_FILE/$FMK_BASE_NAME \
    ${OUT_DIR}/lib/libgmp.a 

  cp -r ${OUT_DIR}/${arch}/include/* ${FMK_FILE}/Headers/

  create_shim

  create_modulemap

  mkdir -p $FMK_DST_DIR > /dev/null 2>&1
  mv $FMK_FILE $FMK_DST_DIR/ 
}

skip_if_dup

make_build_dir

download_tar

build

create_framework