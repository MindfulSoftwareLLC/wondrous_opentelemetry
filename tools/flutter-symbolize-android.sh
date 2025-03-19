#!/bin/bash
flutter symbolize \
  --debug-info=./debug-symbols/wonderous_opentelemetry_android_symbols_.zip --verbose \
  --input=./tools/release-android-stack-trace.txt
