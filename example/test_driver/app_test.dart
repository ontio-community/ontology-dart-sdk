import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

var cryptoTestCases = [
  'testMnemonic',
  'testEcdsaSign',
  'testEcdsaSignWithJavaResult',
  'testSm2Sign',
  'testSm2VerifyTsSig',
  'testEddsaKeypair',
  'testEddsaSign',
  'testScryptEnc',
  'testScryptDec',
  'testToWif',
  'testFromWif',
  'testJavaGeneratedKey',
];

var walletTestCases = [
  'testAccountFromEncrypted',
  'testAccountFromKeystore',
  'testIdentityCreate',
  'testIdentityFromEncrypted',
  'testIdentityFromKeystore',
  'testWalletCreate',
  'testWalletAddAccount',
  'testWalletFromJson',
];

var networkTestCases = [
  'testWsRpcGetNodeCount',
  'testWsRpcBlockHeight',
  'testWsRpcGetBalance',
  'testWsRpcUnclaimedOng',
  'testWsRpcSendRawTx',
  'testWsRpcSendRawTxWait',
];

var testCases = cryptoTestCases + walletTestCases + networkTestCases;

void main() {
  group('Crypto', () {
    var finders = Map<String, SerializableFinder>();
    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests
    setUpAll(() async {
      driver = await FlutterDriver.connect();
      testCases.forEach((name) => finders[name] = find.byValueKey(name));
    });

    // Close the connection to the driver after the tests have completed
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    testCases.forEach((name) {
      test(name, () async {
        var finder = finders[name];
        var text = await driver.getText(finder);
        expect(text.contains('yes'), true);
      });
    });
  });
}
