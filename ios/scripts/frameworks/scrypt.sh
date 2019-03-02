#!/usr/bin/env bash

DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR=${DIR}/build/scrypt
SRC_DIR=${BUILD_DIR}/libscrypt
OUT_DIR=${BUILD_DIR}/out

FMK_BASE_NAME=scrypt
FMK_FILE_NAME=scrypt.framework
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

git_clone() {
  if [ -d "${SRC_DIR}" ]; then
    return
  fi

  git clone https://github.com/technion/libscrypt.git $SRC_DIR
}

replace_makefile() {
    local code=$(cat<<CODE
OBJS= crypto_scrypt-nosse.o sha256.o crypto-mcf.o b64.o crypto-scrypt-saltgen.o crypto_scrypt-check.o crypto_scrypt-hash.o slowequals.o

libscrypt.so.0: \$(OBJS) 
	\$(CC) \$(LDFLAGS) -shared -o libscrypt.so.0  \$(OBJS) -lm -lc
	ar rcs libscrypt.a  \$(OBJS)
	
clean:
	rm -f *.o reference libscrypt.so* libscrypt.a endian.h
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
  cp $SRC_DIR/libscrypt.a $OUT_DIR/ios.a

  echo "Building simulator..."
  make clean
  make CC="$(xcrun --sdk iphonesimulator --find clang) -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) -fno-common -O2 -arch x86_64"
  cp $SRC_DIR/libscrypt.a $OUT_DIR/sim.a
}

create_shim() {
  local code=$(cat<<CODE
#ifndef ScryptHelper_h
#define ScryptHelper_h

#include <scrypt/libscrypt.h>

#endif
CODE
)

  echo "${code}" > $FMK_FILE/shim.h
}

create_modulemap() {
  mkd "${FMK_FILE}/Modules"

  local code=$(cat<<CODE
module Scrypt {
  header "shim.h"
  export *
}
CODE
)

  echo "${code}" > ${FMK_FILE}/Modules/module.modulemap
}

create_fmk() {
  echo "Creating ${FMK_FILE_NAME}..."
  rm -rf ${FMK_FILE}
  mkd "${FMK_FILE}/Headers"
  mkd "${OUT_DIR}/lib"

  lipo $OUT_DIR/ios.a $OUT_DIR/sim.a -create -output ${OUT_DIR}/libscrypt.a

  libtool -no_warning_for_no_symbols -static -o \
    $FMK_FILE/$FMK_BASE_NAME \
    ${OUT_DIR}/libscrypt.a

  cp -r ${SRC_DIR}/libscrypt.h ${FMK_FILE}/Headers/

  create_shim

  create_modulemap

  mkdir -p $FMK_DST_DIR > /dev/null 2>&1
  mv $FMK_FILE $FMK_DST_DIR/
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