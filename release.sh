#!/bin/bash

# first, build the beta versaion
xcodebuild clean archive -workspace Sizung.xcworkspace -archivePath "./archives/SizungBeta_$(git rev-parse --abbrev-ref HEAD)" -scheme SizungStaging

# build production
xcodebuild clean archive -workspace Sizung.xcworkspace -archivePath "./archives/Sizung_$(git rev-parse --abbrev-ref HEAD)" -scheme Sizung
open "./archives/Sizung_$(git rev-parse --abbrev-ref HEAD)"

open archives

# clean
xcodebuild clean -workspace Sizung.xcworkspace -archivePath "./archives/Sizung_$(git rev-parse --abbrev-ref HEAD)" -scheme Sizung
