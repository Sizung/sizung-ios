#!/bin/bash

# stop on error
set -e

echo "Enter Email of iTunes Connect user, followed by [ENTER]:"
read connect_email

echo "Enter Password of iTunes Connect user, followed by [ENTER] (Will not be shown here):"
read -s connect_password

# build beta version
echo "Building beta version - see archives/beta.log"
xcodebuild clean archive -workspace Sizung.xcworkspace -scheme SizungStaging 1> archives/beta.log

# store version
store_filename="./archives/Sizung_$(git rev-parse --abbrev-ref HEAD)"
# build
echo "Building store version - see archives/store.log"
xcodebuild clean archive -workspace Sizung.xcworkspace -archivePath $store_filename -scheme Sizung  1> archives/store.log
# upload
echo "Uploading store version - see archives/upload.log"
altool --upload-app -f "$(store_filename).xcarchive" -u $connect_email -p $connect_password 1> archives/upload.log

# clean
echo "Cleanup step - see archives/clean.log"
xcodebuild clean build -workspace Sizung.xcworkspace -scheme Sizung 1> archives/clean.log

# delete logs on success
rm archives/*.log
