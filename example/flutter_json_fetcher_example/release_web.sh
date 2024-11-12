#!/bin/sh

# This script is used to upload web app to justprodev.com GH Pages

WEB_PATH=/demo/cached_image

# Build the project
flutter build  web --wasm --base-href $WEB_PATH

# copy the build to the gh-pages branch
cp -r build/web/* ../../justprodev.github.io$WEB_PATH
cd ../../justprodev.github.io$WEB_PATH
git pull
git add .
git commit -m "update $WEB_PATH demo"
git push origin master

