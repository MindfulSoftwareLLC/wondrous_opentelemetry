# Debugging Flutter Stack Traces from OpenTelemetry

This guide provides multiple approaches to symbolize Flutter stack traces collected in OpenTelemetry.

## Understanding the Challenge

We've encountered a persistent error when trying to symbolize Flutter stack traces:

```
Failed to decode symbols file for loading unit 1
```

This error occurs despite:
1. Having properly generated debug symbols
2. Not using deferred loading in the app (which would create multiple loading units)
3. Trying multiple approaches to structure the debug symbols

## Approaches to Try

### 1. Using Flutter's Symbolizer with Properly Formatted ZIP

The first approach is to create a ZIP file with a structure that Flutter's symbolizer expects:

```bash
chmod +x tools/create-proper-symbols-zip.sh
./tools/create-proper-symbols-zip.sh
./tools/symbolize-with-proper-zip.sh
```

### 2. Using Flutter's Symbolizer with Engine Symbol Structure

This approach creates a special structure that mimics Flutter engine symbols:

```bash
chmod +x tools/create-engine-symbols.sh
./tools/create-engine-symbols.sh
./tools/symbolize-with-engine.sh
```

### 3. Using Android NDK Tools Directly

If Flutter's symbolizer doesn't work, we can bypass it and use Android NDK tools directly:

```bash
chmod +x tools/direct-ndk-symbolize.sh
./tools/direct-ndk-symbolize.sh
```

This approach requires having the Android NDK installed and properly set up.

## Understanding Flutter Stack Trace Formats

Flutter stack traces can appear in different formats:

### Format 1: Flutter Crash Reports
```
#00 abs 0000006e1974e903 virt 00000000006e4903 _kDartIsolateSnapshotInstructions+0x49dec3
```

### Format 2: Android Native Crashes
```
#00 pc 000000000049dec3 libapp.so
```

For symbolization, we sometimes need to convert between these formats.

## Manual Symbolization with addr2line

If all else fails, you can try manually symbolizing addresses:

1. Find addr2line in your Android NDK:
   ```
   find $ANDROID_HOME -name "*addr2line*"
   ```

2. Use it to symbolize an address:
   ```
   /path/to/aarch64-linux-android-addr2line -e path/to/app.android-arm64.symbols -f -C 0x49dec3
   ```

## OpenTelemetry Integration

When capturing Flutter stack traces in OpenTelemetry:

1. Make sure you capture the full stack trace including:
   - Process ID (pid)
   - Thread ID (tid)
   - Architecture (arm64)
   - Build ID (very important for matching with debug symbols)
   - Memory addresses in the correct format

2. Store your debug symbols in a permanent location:
   - Keep them versioned alongside your app releases
   - Include the APK along with the symbols for reference

3. Consider setting up an automated symbolization service:
   - When a stack trace is received, automatically try to symbolize it
   - Fall back to manual symbolization if automatic methods fail

## Building Flutter Apps for Better Symbolization

When building your Flutter app for release:

```bash
flutter build apk --release --split-debug-info=./debug-symbols/android
```

This ensures that debug symbols are properly generated.

## Future Improvements

Consider implementing these improvements to your workflow:

1. Implement a service that automatically symbolizes stack traces received in OpenTelemetry
2. Add build ID verification to ensure symbols match the exact build
3. Maintain a library of debug symbols for all app versions
4. Add more robust error handling for stack trace parsing

## Resources

- [Flutter Symbolization Documentation](https://flutter.dev/docs/testing/code-debugging#interpreting-stack-traces)
- [Android NDK Symbolization Tools](https://developer.android.com/ndk/guides/ndk-stack)
- [OpenTelemetry Best Practices](https://opentelemetry.io/docs/instrumentation/java/manual/)
