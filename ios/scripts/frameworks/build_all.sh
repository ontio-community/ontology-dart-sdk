#!/usr/bin/env bash

: '
This script automatically downloads some C libs then creates some frameworks from them:

* base58.framework
* gmp.framework
* openssl.framework
* scrypt.framwork
'

DIR="$(cd "$(dirname "$0")" && pwd)"

cd "${DIR}"

bash base58.sh  
bash gmp.sh  
bash openssl.sh   
bash scrypt.sh 
