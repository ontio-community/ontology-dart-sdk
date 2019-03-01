<h1 align="center">Dart SDK For Ontology blockchain</h1>

This is a Dart SDK for the Ontology blockchain and could be used in the Flutter development.

It supports:

* Wallet management
* Digital identity management
* Digital asset management
* Smart Contract deployment and invocation
* Ontology blockchain API

It's recommend to take a quick view of the [Ontology Development Guide](https://dev-docs.ont.io/#/docs-en/SDKs/00-overview) before your development. The [test cases](example/lib/test/cases) folder contains various examples they are also worth a glance.

## Install

For using this package in your project you'd firstly update your `pubspec.yaml` file to contains blew lines:

```yaml
dependencies:
  ontology_dart_sdk: ^0.0.1
```

and then run the package installation command:

```bash
flutter packages get
```

## Run the tests

Testing in flutter is interesting, our test code and business code run in two separate processes. The test code takes  screen captures of the running business code to perform further predicate code. For more details under this mechanism please refer [integration testing](https://flutter.dev/docs/cookbook/testing/integration/introduction).

Here are the steps to start the tests:

1. Downloading the executable binary file of Ontology from it's [release page](https://github.com/ontio/ontology/releases). The version used in the tests is `ontology version v1.6.0-8-g754303c0`
2. Copying the test wallet located in file [example/lib/test/common/wallet.dart](example/lib/test/common/wallet.dart) and save it into file `wallet.dat` then put the saved wallet file and the Ontology binary from step 1 under the same directory.
3. Starting Ontology node runs in test mode `./ontology --testmode --loglevel=1`
4. Starting the tests: `cd example/ && flutter drive --target=test_driver/app.dart`

Below is a screenshot from tests:

<img src="doc/img/tests.gif" width="500">