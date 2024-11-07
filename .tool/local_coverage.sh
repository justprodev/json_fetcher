#!/bin/sh

# generate coverage report in html format

flutter test -j 1 --coverage || exit 1
genhtml coverage/lcov.info -o coverage/html || exit 1
open coverage/html/index.html