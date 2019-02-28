typedef Future<bool> Tester();

class TestCase {
  String name;
  Tester runner;

  TestCase(this.name, this.runner);
}
