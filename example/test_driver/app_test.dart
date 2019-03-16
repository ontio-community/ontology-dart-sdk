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
  'testInvalidPassword',
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
  'testWithdrawOng',
];

var transferTestCases = [
  'testTransferOnt',
  'testTransferOng',
  'testTransferWithSm2Account',
];

var ontidTestCases = [
  'testRegisterOntId',
  'testGetDDO',
];

var oep4TestCases = [
  'testOep4Init',
  'testOep4QueryName',
  'testOep4QuerySymbol',
  'testOep4QueryDecimals',
  'testOep4QueryTotalSupply',
  'testOep4QueryBalance',
  'testOep4Transfer',
  'testOep4Approvel',
  'testOep4QueryAlloance',
  'testOep4TransferFrom',
  'testOep4TransferMulti',
];

var neovmTestCase = [
  'testNeovmName',
  'testNeovmHello',
  'testNeovmTrue',
  'testNeovmFalse',
  'testNeovmList',
  'testNeovmStruct',
  'testNeovmSetMap',
  'testNeovmGetMap',
  'testNeovmSetMapInMap',
  'testNeovmGetMapInMap',
];

var testCases = cryptoTestCases +
    walletTestCases +
    networkTestCases +
    transferTestCases +
    ontidTestCases +
    oep4TestCases +
    neovmTestCase;

void main() {
  group('test', () {
    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    testCases.forEach((name) {
      test(name, () async {
        var finder = find.byValueKey(name);
        await driver.waitFor(finder, timeout: Duration(seconds: 30));
        var text = await driver.getText(finder);
        expect(text.contains('yes'), true);
      });
    });
  });
}
