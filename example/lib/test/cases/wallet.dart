import 'dart:convert';
import '../test_case.dart';
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/common.dart';
import 'package:ontology_dart_sdk/wallet.dart';

var testCases = [
  TestCase('testAccountFromEncrypted', () async {
    var prikey = await PrivateKey.random();
    var pwd = 'password';
    var acc = await Account.create(pwd, prikey: prikey);
    var enc = acc.encryptedKey;
    var addr = await Address.fromBase58(acc.address);
    acc = await Account.fromEncryptedKey(enc, 'mickey', pwd, addr, acc.salt);
    var dec = await acc.decrypt(pwd);
    return Convert.bytesToHexStr(dec.raw) == Convert.bytesToHexStr(prikey.raw);
  }),
  TestCase('testAccountFromKeystore', () async {
    var str = """
    {"address":"AG9W6c7nNhaiywcyVPgW9hQKvUYQr5iLvk","key":"+UADcReBcLq0pn/2Grmz+UJsKl3ryop8pgRVHbQVgTBfT0lho06Svh4eQLSmC93j","parameters":{"curve":"P-256"},"label":"11111","scrypt":{"dkLen":64,"n":4096,"p":8,"r":8},"salt":"IfxFV0Fer5LknIyCLP2P2w==","type":"A","algorithm":"ECDSA"}
    """;
    var ks = Keystore.fromJson(jsonDecode(str));
    var acc = await Account.fromKeystore(ks, '111111');
    var addrOk = acc.address == 'AG9W6c7nNhaiywcyVPgW9hQKvUYQr5iLvk';
    var encOk = Convert.bytesToBase64(acc.encryptedKey.raw) ==
        '+UADcReBcLq0pn/2Grmz+UJsKl3ryop8pgRVHbQVgTBfT0lho06Svh4eQLSmC93j';
    return addrOk && encOk;
  }),
  TestCase('testIdentityCreate', () async {
    var prikey = await PrivateKey.random();
    var pwd = 'password';
    var label = 'mickey';
    var id = await Identity.create(prikey, pwd, label);
    var json = jsonEncode(id);
    id = Identity.fromJson(jsonDecode(json));
    var pri = await id.getPrivateKey(pwd);
    return Convert.bytesToHexStr(prikey.raw) == Convert.bytesToHexStr(pri.raw);
  }),
  TestCase('testIdentityFromEncrypted', () async {
    var prikey = await PrivateKey.random();
    var pwd = 'password';
    var label = 'mickey';
    var id = await Identity.create(prikey, pwd, label);
    var enc = id.controls[0].encryptedKey;
    var addr = await Address.fromBase58(id.controls[0].address);
    var salt = id.controls[0].salt;
    id = await Identity.fromEncryptedKey(enc, 'mickey', pwd, addr, salt);
    return id.label == label;
  }),
  TestCase('testIdentityFromKeystore', () async {
    var str = """
    {"address":"AG9W6c7nNhaiywcyVPgW9hQKvUYQr5iLvk","key":"+UADcReBcLq0pn/2Grmz+UJsKl3ryop8pgRVHbQVgTBfT0lho06Svh4eQLSmC93j","parameters":{"curve":"P-256"},"label":"11111","scrypt":{"dkLen":64,"n":4096,"p":8,"r":8},"salt":"IfxFV0Fer5LknIyCLP2P2w==","type":"I","algorithm":"ECDSA"}
    """;
    var ks = Keystore.fromJson(jsonDecode(str));
    var id = await Identity.fromKeystore(ks, '111111');
    var addrOk = id.controls[0].address == 'AG9W6c7nNhaiywcyVPgW9hQKvUYQr5iLvk';
    var encOk = Convert.bytesToBase64(id.controls[0].encryptedKey.raw) ==
        '+UADcReBcLq0pn/2Grmz+UJsKl3ryop8pgRVHbQVgTBfT0lho06Svh4eQLSmC93j';
    return addrOk && encOk;
  }),
  TestCase('testWalletCreate', () async {
    var w = Wallet('mickey');
    var json = jsonEncode(w);
    return json != "";
  }),
  TestCase('testWalletAddAccount', () async {
    var w = Wallet('mickey');
    var prikey = await PrivateKey.random();
    var acc = await Account.create('password', prikey: prikey, label: 'mickey');
    w.addAccount(acc);
    return w.accounts.length == 1;
  }),
  TestCase('testWalletFromJson', () async {
    var str = """
    {"name":"MyWallet","version":"1.1","scrypt":{"p":8,"n":16384,"r":8,"dkLen":64},"accounts":[{"address":"AUr5QUfeBADq6BMY6Tp5yuMsUNGpsD7nLZ","enc-alg":"aes-256-gcm","key":"KysbyR9wxnD2XpiH5Xgo4q0DTqKJxaA+Sz3I60fIvsn7wktC9Utb1XYzfHt4mjjl","algorithm":"ECDSA","salt":"dg2t+nlEDEvhP52epby/gw==","parameters":{"curve":"P-256"},"label":"","publicKey":"03f631f975560afc7bf47902064838826ec67794ddcdbcc6f0a9c7b91fc8502583","signatureScheme":"SHA256withECDSA","isDefault":true,"lock":false}]}
    """;
    var w = Wallet.fromJson(jsonDecode(str));
    return w.accounts.length == 1 && w.identities.length == 0;
  }),
];