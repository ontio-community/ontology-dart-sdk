#!/usr/bin/env bash

ROOT="$(cd "$(dirname "$0")" && pwd)"/../

# format swift files
swiftformat $ROOT

# format objc files
find $ROOT/ios/Classes/ -iname *.h -o -iname *.m | xargs clang-format -i -style=file

flutter format lib