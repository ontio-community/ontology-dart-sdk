import 'package:flutter/material.dart';
import 'test_state.dart';
import 'crypto_tests.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends TestState {
  void setupTests() {
    testCases.forEach((t) => addTest(t));
  }
}
