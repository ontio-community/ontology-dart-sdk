import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'test_case.dart';

abstract class TestState extends State {
  var _tests = <TestCase>[];
  var _allCnt = 0;
  var _passCnt = 0;
  var _errCnt = 0;
  var _testStates = <dynamic>[];
  var _testWidgets = <Widget>[];

  var _scrollCtrl = ScrollController(initialScrollOffset: 0);

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

  updateTestState(dynamic stateInfo, int allCnt, int errCnt, int doneCnt) {
    var name = stateInfo['name'];
    var state = _testStates.firstWhere((s) => s['name'] == name, orElse: () {
      _testStates.add(stateInfo);
      return stateInfo;
    });

    state['state'] = stateInfo['state'];
    state['stateColor'] = stateInfo['stateColor'];

    setState(() {
      _allCnt = allCnt;
      _errCnt = errCnt;
      _passCnt = doneCnt;
      _testWidgets = _testStates.map((s) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 8,
              child: Padding(
                padding: EdgeInsets.only(left: 30),
                child: Text(
                  '${s['name']}:',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 30),
              child: s['state'] == 'testing'
                  ? Text('testing',
                      style: TextStyle(
                        color: s['stateColor'],
                      ))
                  : Text('${s['state']}',
                      key: Key(s['name']),
                      style: TextStyle(
                        color: s['stateColor'],
                      )),
            ),
          ],
        );
      }).toList();
    });

    if (_scrollCtrl.hasClients) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        var scrollPosition = _scrollCtrl.position;
        if (scrollPosition.maxScrollExtent != null) {
          _scrollCtrl.animateTo(
            scrollPosition.maxScrollExtent,
            duration: new Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> runTests() async {
    var allCnt = _tests.length;
    var doneCnt = 0;
    var errCnt = 0;
    for (var test in _tests) {
      var name = test.name;
      var state = 'testing';
      var stateColor = Colors.cyan;

      var stateInfo = {'name': name, 'state': state, 'stateColor': stateColor};
      updateTestState(stateInfo, allCnt, errCnt, doneCnt);
      try {
        await test.runner();
        doneCnt += 1;
        stateInfo['state'] = 'yes';
        stateInfo['stateColor'] = Colors.green;
      } catch (e, stacktrace) {
        errCnt += 1;
        stateInfo['state'] = 'no';
        stateInfo['stateColor'] = Colors.red;
        print('[NOT PASS] $name: ' + e.toString());
        print(stacktrace.toString());
      }
      updateTestState(stateInfo, allCnt, errCnt, doneCnt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('A $_allCnt'),
                  Text(
                    'P $_passCnt',
                    style: TextStyle(color: Colors.green),
                  ),
                  Text(
                    'E $_errCnt',
                    style: TextStyle(color: Colors.red),
                  )
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _testWidgets,
                  )),
            )
          ],
        )));
  }
}
