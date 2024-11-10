#!/bin/sh

# run tests & generate coverage

set -e

dart pub global activate coverage
dart test test/cache_web_test.dart -p chrome --coverage="coverage"
dart test -j 1 --coverage="coverage"
format_coverage --lcov --in=coverage --out=coverage/lcov.info --package=. --report-on=lib