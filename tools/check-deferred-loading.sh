#!/bin/bash
# Script to check for deferred loading in a Flutter project
set -e

echo "Checking for deferred loading in your Flutter project..."

# Find all Dart files
echo "Searching for Dart files with 'deferred as' imports..."
find . -name "*.dart" -type f -exec grep -l "deferred as" {} \; | sort

echo "Searching for 'loadLibrary()' calls..."
find . -name "*.dart" -type f -exec grep -l "loadLibrary()" {} \; | sort

echo "If you see any files listed above, your app uses deferred loading."
echo "This means your app may have multiple loading units, which requires"
echo "special handling for symbolization."

echo "Checking build.gradle for split-per-abi configuration..."
cat ./android/app/build.gradle | grep -A 10 "splits {"

echo "If you're seeing the 'Failed to decode symbols file for loading unit 1' error,"
echo "make sure your debug symbols contain information for all loading units."
echo "You might need to modify how debug symbols are generated in your build script."

echo "Check complete."
