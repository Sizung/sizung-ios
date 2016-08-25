#!/bin/bash

# stop on error
set -e

versionNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Sizung/Info.plist)

echo "Enter Email of iTunes Connect user, followed by [ENTER]:"
read connect_email

echo "Enter Password of iTunes Connect user, followed by [ENTER] (Will not be shown here):"
read -s connect_password

echo "______________"
echo "starting build for v$versionNumber"
echo "______________\n"

# build beta version
echo "Building beta version - see archives/beta.log"
xcodebuild clean archive \
  -workspace Sizung.xcworkspace \
  -scheme SizungStaging \
  1> archives/beta.log

# store version
store_filename="./archives/Sizung_$(git rev-parse --abbrev-ref HEAD)"
# build
echo "Building store version - see archives/store.log"
xcodebuild clean archive -workspace Sizung.xcworkspace \
  -exportPath $store_filename \
  -scheme Sizung \
  1> archives/store.log

echo "Exporting store version - see archives/export.log"
xcodebuild -exportArchive -exportFormat ipa \
  -archivePath "$store_filename.xcarchive" \
  -exportPath "$store_filename.ipa" \
  -exportProvisioningProfile "Sizung iOS Prod" \
  1> archives/export.log

# upload
echo "Uploading store version - see archives/upload.log"
altool --upload-app \
  -f "$store_filename.ipa" \
  -u $connect_email \
  -p $connect_password \
  1> archives/upload.log

# clean
echo "Cleanup step - see archives/clean.log"
xcodebuild clean build -workspace Sizung.xcworkspace -scheme Sizung 1> archives/clean.log

# delete logs on success
rm archives/*.log
