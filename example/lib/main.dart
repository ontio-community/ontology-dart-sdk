import 'package:flutter/material.dart';
import 'test/test_state.dart';
import 'test/cases/crypto.dart' as crypto;
import 'test/cases/wallet.dart' as wallet;
import 'test/cases/network.dart' as network;
import 'test/cases/transfer.dart' as transfer;
import 'test/cases/ontid.dart' as ontid;
import 'test/cases/oep4.dart' as oep4;
import 'test/cases/neovm.dart' as neovm;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends TestState {
  void setupTests() {
    var testCases = crypto.testCases +
        wallet.testCases +
        network.testCases +
        transfer.testCases +
        ontid.testCases +
        oep4.testCases +
        neovm.testCases;
    testCases.forEach((t) => addTest(t));
  }
}
