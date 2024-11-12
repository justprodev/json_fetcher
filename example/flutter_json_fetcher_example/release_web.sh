#!/bin/sh

# This script is used to upload web app to justprodev.com GH Pages
# Intended to be run locally

set -e

GITHUB_PAGES_PATH=../../../justprodev.github.io
DIR_PATH=demo/json_fetcher_flutter
WEB_PATH=/$DIR_PATH/

# Build the project
flutter build  web --wasm --base-href $WEB_PATH --release

echo "Copying files to $DIR_PATH"
cp -r build/web/* $GITHUB_PAGES_PATH/$DIR_PATH/
cd $GITHUB_PAGES_PATH/$DIR_PATH/
echo "Get movies.json from https://github.com/prust/wikipedia-movie-data"
curl -o movies.json https://raw.githubusercontent.com/prust/wikipedia-movie-data/master/movies.json
git add .
git commit -m "update $DIR_PATH demo"
git push origin master
open https://justprodev.com$WEB_PATH
