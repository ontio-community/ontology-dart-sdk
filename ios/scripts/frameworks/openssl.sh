#!/usr/bin/env bash

# references https://wiki.openssl.org/index.php/Compilation_and_Installation

OPENSSL_VER="1.1.1"

ARCHS="x86_64 armv7 arm64"

DIR="$(cd "$(dirname "$0")" && pwd)"

BUILD_DIR=${DIR}/build/openssl

OPENSSL_TAR_BASE_NAME=OpenSSL_${OPENSSL_VER//./_}
OPENSSL_TAR_FILE_NAME=${OPENSSL_TAR_BASE_NAME}.tar.gz
OPENSSL_TAR_FILE=${BUILD_DIR}/${OPENSSL_TAR_FILE_NAME}
OPENSSL_TAR_X_DIR=${BUILD_DIR}/openssl-${OPENSSL_TAR_BASE_NAME}

OUT_DIR=${BUILD_DIR}/out

LOG=${BUILD_DIR}/openssl.log

FMK_BASE_NAME=openssl
FMK_FILE_NAME=openssl.framework
FMK_FILE=${BUILD_DIR}/${FMK_FILE_NAME}
FMK_DST=${DIR}/../../Frameworks/${FMK_FILE_NAME}

# http://fitnr.com/showing-a-bash-spinner.html
spinner() {
  local pid=$!
  local delay=0.35
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

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
  if [ ! -d ${OPENSSL_TAR_X_DIR} ]; then
    if [ ! -f ${OPENSSL_TAR_FILE} ]; then
      echo "Downloading OpenSSL ${OPENSSL_VER}"
      curl -L https://github.com/openssl/openssl/archive/${OPENSSL_TAR_FILE_NAME} > ${OPENSSL_TAR_FILE}
    fi
    tar zxf ${OPENSSL_TAR_FILE} -C ${BUILD_DIR}
    chmod u+x ${OPENSSL_TAR_X_DIR}/Configure
  else
    echo "Using ${OPENSSL_TAR_FILE}"
  fi
}

build_for() {
  local arch=$1
  local tpl=""
  local cfg=""

  local prefix="${OUT_DIR}/${arch}"

  if [ -d "${prefix}" ]; then
    return
  fi

  if [ "${arch}" == "x86_64" ]; then
    tpl="iossimulator-xcrun"
  elif [[ "${arch}" == "armv7" || "${arch}" == "armv7s" ]]; then
    tpl="ios-xcrun"
    cfg="-fembed-bitcode"
  elif [ "${arch}" == "arm64" ]; then
    tpl="ios64-xcrun"
    cfg="-fembed-bitcode"
  fi

  cd ${OPENSSL_TAR_X_DIR}

  make clean

  ./Configure ${tpl} ${cfg} no-shared no-dso no-hw no-engine --prefix="${prefix}"
  make
  make install_sw
}

build() {
  echo "Archs: ${ARCHS}"
  echo -e "Open below command in a new tab to see building log:\n\n  tail -f ${LOG}\n"
  for arch in ${ARCHS}
  do
    echo "Building for: ${arch}"
    (build_for $arch >> "${LOG}" 2>&1) & spinner
  done
}

create_shim() {
  local code=$(cat<<CODE
#ifndef OpenSSLHelper_h
#define OpenSSLHelper_h

#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/bio.h>
#include <openssl/sha.h>
#include <openssl/hmac.h>
#include <openssl/rand.h>
#include <openssl/bn.h>
#include <openssl/ec.h>
#include <openssl/ripemd.h>
#include <openssl/ed25519.h>

#endif
CODE
)

  echo "${code}" > $FMK_FILE/shim.h
}

create_modulemap() {
  mkd "${FMK_FILE}/Modules"

  local code=$(cat<<CODE
module OpenSSL {
  header "shim.h"
  export *
}
CODE
)

  echo "${code}" > ${FMK_FILE}/Modules/module.modulemap
}

create_ed25519_header () {
  local code=$(cat<<CODE
#ifndef ED25519_h
#define ED25519_h

#include <stdlib.h>
#include <stdint.h>

int ED25519_sign(uint8_t *out_sig, const uint8_t *message, size_t message_len,
                 const uint8_t public_key[32], const uint8_t private_key[32]);
int ED25519_verify(const uint8_t *message, size_t message_len,
                   const uint8_t signature[64], const uint8_t public_key[32]);
void ED25519_public_from_private(uint8_t out_public_key[32],
                                 const uint8_t private_key[32]);

#endif
CODE
  )

  echo "${code}" > ${FMK_FILE}/Headers/ed25519.h
}

create_framework() {
  echo "Creating ${FMK_FILE_NAME}..."
  rm -rf ${FMK_FILE}
  mkd "${FMK_FILE}/Headers"
  mkd "${OUT_DIR}/lib"

  local libcrypto=""
  local libssl=""
  for arch in ${ARCHS}
  do
    libcrypto="${libcrypto} ${OUT_DIR}/${arch}/lib/libcrypto.a"
    libssl="${libssl} ${OUT_DIR}/${arch}/lib/libssl.a"
  done

  lipo ${libcrypto} -create -output "${OUT_DIR}/lib/libcrypto.a"
  lipo ${libssl} -create -output "${OUT_DIR}/lib/libssl.a"

  libtool -no_warning_for_no_symbols -static -o \
    $FMK_FILE/$FMK_BASE_NAME \
    ${OUT_DIR}/lib/libcrypto.a ${OUT_DIR}/lib/libssl.a

  cp -r ${OUT_DIR}/${arch}/include/openssl/* ${FMK_FILE}/Headers/

  create_ed25519_header

  create_shim

  create_modulemap

  cp -rf $FMK_FILE ${DIR}/../../Frameworks/
}

skip_if_dup() {
  if [ -d "${FMK_DST}" ]; then 
    exit 0
  fi
}

skip_if_dup

make_build_dir

download_tar

build

create_framework
