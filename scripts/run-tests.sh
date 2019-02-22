#!/usr/bin/env bash

ROOT="$(cd "$(dirname "$0")" && pwd)"/../

# clean build cache
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/
cd $ROOT/example/ios/
# should to recreate .xcworkspace file after cleans build
pod install > /dev/null 2>&1
cd $ROOT

# run tests
set -o pipefail && \
  xcodebuild \
    -workspace example/ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 6,OS=12.1' \
    test | xcpretty --test --color 