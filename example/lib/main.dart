import 'package:flutter/material.dart';
import 'test/test_state.dart';
import 'test/cases/crypto.dart' as crypto;
import 'test/cases/wallet.dart' as wallet;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends TestState {
  void setupTests() {
    crypto.testCases.forEach((t) => addTest(t));
    wallet.testCases.forEach((t) => addTest(t));
  }
}
