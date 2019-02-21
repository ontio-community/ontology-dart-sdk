#!/usr/bin/env bash

DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR=${DIR}/build/base58
SRC_DIR=${BUILD_DIR}/libbase58
OUT_DIR=${BUILD_DIR}/out

FMK_BASE_NAME=base58
FMK_FILE_NAME=base58.framework
FMK_FILE=${BUILD_DIR}/${FMK_FILE_NAME}
FMK_DST=${DIR}/../../Frameworks/${FMK_FILE_NAME}

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

git_clone() {
  if [ -d "${SRC_DIR}" ]; then
    return
  fi

  git clone https://github.com/bitcoin/libbase58.git $SRC_DIR
}

replace_makefile() {
    local code=$(cat<<CODE
OBJS= base58.o

libscrypt.so.0: \$(OBJS) 
	\$(CC) \$(LDFLAGS) -shared -o libbase58.so.0  \$(OBJS) -lm -lc
	ar rcs libbase58.a  \$(OBJS)
	
clean:
	rm -f *.o reference libbase58.so* libbase58.a
CODE
)

  echo "${code}" > $SRC_DIR/Makefile
}

build() {
  mkd $OUT_DIR

  cd $SRC_DIR

  echo "Building ios.."
  make clean
  make CC="$(xcrun --sdk iphoneos --find clang) -isysroot $(xcrun --sdk iphoneos --show-sdk-path) -fembed-bitcode -fno-common -O2 -arch armv7 -arch arm64"
  cp $SRC_DIR/libbase58.a $OUT_DIR/ios.a

  echo "Building simulator..."
  make clean
  make CC="$(xcrun --sdk iphonesimulator --find clang) -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) -fno-common -O2 -arch x86_64"
  cp $SRC_DIR/libbase58.a $OUT_DIR/sim.a
}

create_shim() {
  local code=$(cat<<CODE
#ifndef Base58Helper_h
#define Base58Helper_h

#include <base58/libbase58.h>

#endif
CODE
)

  echo "${code}" > $FMK_FILE/shim.h
}

create_modulemap() {
  mkd "${FMK_FILE}/Modules"

  local code=$(cat<<CODE
module Base58 {
  header "shim.h"
  export *
}
CODE
)

  echo "${code}" > ${FMK_FILE}/Modules/module.modulemap
}

patch_header() {
  local diff=$(cat<<CODE
--- libbase58.h	2018-12-02 13:15:25.000000000 +0800
+++ libbase58.stdint.h	2018-12-02 13:36:12.000000000 +0800
@@ -3,6 +3,7 @@

 #include <stdbool.h>
 #include <stddef.h>
+#include <stdint.h>

 #ifdef __cplusplus
 extern "C" {
CODE
)

  cd ${FMK_FILE}/Headers/
  echo "${diff}" > libbase58.h.patch
  patch < libbase58.h.patch
  rm libbase58.h.patch
}

create_fmk() {
  echo "Creating ${FMK_FILE_NAME}..."
  rm -rf ${FMK_FILE}
  mkd "${FMK_FILE}/Headers"
  mkd "${OUT_DIR}/lib"

  lipo $OUT_DIR/ios.a $OUT_DIR/sim.a -create -output ${OUT_DIR}/libbase58.a

  libtool -no_warning_for_no_symbols -static -o \
    $FMK_FILE/$FMK_BASE_NAME \
    ${OUT_DIR}/libbase58.a

  cp -r ${SRC_DIR}/libbase58.h ${FMK_FILE}/Headers/

  create_shim

  create_modulemap

  patch_header

  cp -rf $FMK_FILE ${DIR}/../../Frameworks/
}

skip_if_dup() {
  if [ -d "${FMK_DST}" ]; then 
    exit 0
  fi
}

skip_if_dup

make_build_dir

git_clone

replace_makefile

build

create_fmk