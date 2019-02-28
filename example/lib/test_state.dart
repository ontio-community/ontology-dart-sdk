import 'package:flutter/material.dart';
import 'dart:async';
import 'test_case.dart';

abstract class TestState extends State {
  var _tests = <TestCase>[];
  var _progress = '0/10';
  var _testResults = <Widget>[];

  @override
  void initState() {
    super.initState();
    setupTests();
    runTests();
  }

  void addTest(TestCase test) {
    _tests.add(test);
  }

  void setupTests();

  Future<void> runTests() async {
    var allCnt = _tests.length;
    setState(() {
      _progress = '0/' + allCnt.toString();
    });

    var doneCnt = 0;
    var results = <dynamic>[];
    for (var test in _tests) {
      var name = test.name;
      var pass = false;
      try {
        pass = await test.runner();
      } catch (e) {}
      results.add({'name': name, 'pass': pass ? 'yes' : 'no'});
      doneCnt += 1;

      setState(() {
        _progress = '$doneCnt/$allCnt';
        _testResults = results
            .map((res) => new Text(
                  '${res['name']}: ${res['pass']}',
                  key: Key(res['name']),
                ))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Column(children: [
            Center(
              child: Text('Progress $_progress'),
            ),
            Column(
              children: _testResults,
            )
          ])),
    );
  }
}
