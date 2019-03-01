import 'dart:convert';
import 'package:ontology_dart_sdk/wallet.dart';

/// below this a wallet content for run tests in testmode
/// copy and save this json string as a file named `wallet.dat` 
/// then put this file under the samve directory as the `ontology` binary executable file
const walletJson = """
{
  "accounts": [
    {
      "address": "AUr5QUfeBADq6BMY6Tp5yuMsUNGpsD7nLZ",
      "algorithm": "ECDSA",
      "enc-alg": "aes-256-gcm",
      "hash": "sha256",
      "isDefault": true,
      "key": "Q85bbTpl67SoQ07DJ1Vbx/2UPH/+dRTqIX1AN2jO0T38jseU6ef8C4DiAxAulp8P",
      "label": "f00fda8a",
      "lock": false,
      "parameters": {
        "curve": "P-256"
      },
      "publicKey": "03f631f975560afc7bf47902064838826ec67794ddcdbcc6f0a9c7b91fc8502583",
      "salt": "OqeBJgNFmdPxy8uB4oP4gg==",
      "signatureScheme": "SHA256withECDSA"
    },
    {
      "address": "AL9PtS6F8nue5MwxhzXCKaTpRb3yhtsix5",
      "enc-alg": "aes-256-gcm",
      "key": "vwIgX3qJO+1XikdPAfjAu/clsgS2l2xkEWsRR9XZQ8OyFViX+r/6Yq+cV0wnKQUM",
      "algorithm": "SM2",
      "salt": "xzvrFkHAgsEeX64V+4mpLw==",
      "parameters": {
        "curve": "sm2p256v1"
      },
      "label": "",
      "publicKey": "131403a9b89a0443ded240c3dee97221353d000d0dc905b7c085f4ef558b234a75e122",
      "signatureScheme": "SM3withSM2",
      "isDefault": false,
      "lock": false
    },
    {
      "address": "AecaeSEBkt5GcBCxwz1F41TvdjX3dnKBkJ",
      "algorithm": "ECDSA",
      "enc-alg": "aes-256-gcm",
      "hash": "sha256",
      "isDefault": false,
      "key": "yS/YqQG5zCy7SQGqAjcKBMAK7zWUV4Hd/E7Hn34Tcj6M0uCE2UEZnDtpWKLRaEGK",
      "label": "e68abafe",
      "lock": false,
      "parameters": {
        "curve": "P-256"
      },
      "publicKey": "03624058e31c2830320751a62598f726f70496c534906814d9a77363a2bffa95fe",
      "salt": "88MO1oKDkQR7VjNnoetBVA==",
      "signatureScheme": "SHA256withECDSA"
    },
    {
      "address": "AQvZMDecMoCi2y4V6QKdJBtHW1eV7Vbaof",
      "algorithm": "ECDSA",
      "enc-alg": "aes-256-gcm",
      "hash": "sha256",
      "isDefault": false,
      "key": "Gr4kC1ZmUxCnCYkupgWlrfTsM4NZSgzTN/oA8QMl4zEFdMhz8kzJ5LlAZDlV/YTU",
      "label": "dc81e598",
      "lock": false,
      "parameters": {
        "curve": "P-256"
      },
      "publicKey": "037db763291c98e08108d7df9a66aacc27d1023112c86e7b19e0747f7aa89fc2f7",
      "salt": "bi6hPt525RcQZ1pLVjol3A==",
      "signatureScheme": "SHA256withECDSA"
    }
  ],
  "createTime": "2018-10-31T16:30:24Z",
  "defaultAccountAddress": "AUr5QUfeBADq6BMY6Tp5yuMsUNGpsD7nLZ",
  "defaultOntid": "did:ont:AUr5QUfeBADq6BMY6Tp5yuMsUNGpsD7nLZ",
  "identities": [
    {
      "controls": [
        {
          "address": "AUr5QUfeBADq6BMY6Tp5yuMsUNGpsD7nLZ",
          "algorithm": "ECDSA",
          "enc-alg": "aes-256-gcm",
          "hash": "sha256",
          "id": "keys-1",
          "key": "dsSZMHNGbbvWWoNiRNBWl46iUuGJ0QX6pH+5yJyZZ49VhD55lObAyIa/NI0Lu2Zg",
          "parameters": {
            "curve": "P-256"
          },
          "publicKey": "03f631f975560afc7bf47902064838826ec67794ddcdbcc6f0a9c7b91fc8502583",
          "salt": "TbIyGI+emIoMvrDvknCCIg=="
        }
      ],
      "isDefault": true,
      "label": "2a909d60",
      "lock": false,
      "ontid": "did:ont:AUr5QUfeBADq6BMY6Tp5yuMsUNGpsD7nLZ"
    },
    {
      "controls": [
        {
          "address": "AecaeSEBkt5GcBCxwz1F41TvdjX3dnKBkJ",
          "algorithm": "ECDSA",
          "enc-alg": "aes-256-gcm",
          "hash": "sha256",
          "id": "keys-1",
          "key": "wmyE6YmLUKbpuvhgA1arPbJHMfDOiaOUlny/LwoH4o8/KtPpRbVwgeSRwjpa88F9",
          "parameters": {
            "curve": "P-256"
          },
          "publicKey": "03624058e31c2830320751a62598f726f70496c534906814d9a77363a2bffa95fe",
          "salt": "9mHuICV2menJ6qri6z3JmA=="
        }
      ],
      "isDefault": false,
      "label": "8ff4c8d8",
      "lock": false,
      "ontid": "did:ont:AecaeSEBkt5GcBCxwz1F41TvdjX3dnKBkJ"
    },
    {
      "controls": [
        {
          "address": "AQvZMDecMoCi2y4V6QKdJBtHW1eV7Vbaof",
          "algorithm": "ECDSA",
          "enc-alg": "aes-256-gcm",
          "hash": "sha256",
          "id": "keys-1",
          "key": "7KAPfhtdQyziD+9cNlSxZk2gKUfu994tg0yP2vZPFmSqUQf0E2zSymgME+y7xZqt",
          "parameters": {
            "curve": "P-256"
          },
          "publicKey": "037db763291c98e08108d7df9a66aacc27d1023112c86e7b19e0747f7aa89fc2f7",
          "salt": "sx7GsdbaBL0eOJMA3+1V4A=="
        }
      ],
      "isDefault": false,
      "label": "6fe929a3",
      "lock": false,
      "ontid": "did:ont:AQvZMDecMoCi2y4V6QKdJBtHW1eV7Vbaof"
    }
  ],
  "name": "com.github.ontio",
  "scrypt": {
    "dkLen": 64,
    "n": 16384,
    "p": 8,
    "r": 8
  },
  "version": "1.0"
}
""";

Wallet wallet4test() {
  return Wallet.fromJson(jsonDecode(walletJson));
}
