#!/bin/bash
flutter symbolize \
  --debug-info=/Users/mbushe/dev/mf/otel/wonderous_opentelemetry/debug-symbols/wonderous_opentelemetry_android_symbols_proper.zip \
  --input=./tools/formatted-stack-trace.txt \
  --verbose
