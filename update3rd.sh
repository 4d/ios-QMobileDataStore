#!/bin/bash
# checkout
carthage checkout

# build
mkdir -p "build"
./carthage.sh build --no-use-binaries --platform iOS --cache-builds --log-path "build/log" #

#  https://github.com/Carthage/Carthage/issues/1986?

cat "build/log" | xcpretty
