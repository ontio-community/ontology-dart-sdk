import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Crypto', () {
    // First, define the Finders. We can use these to locate Widgets from the
    // test suite. Note: the Strings provided to the `byValueKey` method must
    // be the same as the Strings we used for the Keys in step 1.
    final platformTextFinder = find.byValueKey('platform');

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

    test('method channel works', () async {
      // Use the `driver.getText` method to verify the counter starts at 0.
      String text = await driver.getText(platformTextFinder);
      expect(text.startsWith("Running on: iOS"), true);
    });
  });
}
