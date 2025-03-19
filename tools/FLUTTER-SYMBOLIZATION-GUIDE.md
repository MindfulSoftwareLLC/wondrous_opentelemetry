# Flutter Symbolization Guide for OpenTelemetry

This guide addresses how to properly symbolize Flutter stack traces captured in OpenTelemetry (OTel) for Android builds.

## Understanding the Error

You're encountering this error:
```
Failed to decode symbols file for loading unit 1
```

This occurs when Flutter's symbolizer can't find or decode the debug symbols for a specific loading unit in your application.

## Key Issues

1. **Using a Directory Instead of a ZIP File**: 
   The error in your script was trying to use a directory path for `--debug-info` instead of a file path. The Flutter symbolizer requires a file (typically a ZIP).

2. **Minimal Stack Trace**: 
   Your stack trace is very minimal and might not contain all the information needed for proper symbolization. Flutter expects a specific format.

3. **Loading Unit Reference**:
   The error specifically mentions "loading unit 1", which suggests:
   - Your app might be using deferred loading (code splitting)
   - The debug symbols might not contain all necessary information for these loading units

## Solutions

### 1. Use the Fixed Symbolization Script

The most straightforward approach is to use the fixed script:

```bash
chmod +x tools/fixed-flutter-symbolize-android.sh
./tools/fixed-flutter-symbolize-android.sh
```

This script:
- Uses the ZIP file directly (not a directory)
- Tries both your original stack trace and an enhanced version
- Provides detailed output to help diagnose issues

### 2. Check for Deferred Loading

If your app uses deferred loading, this could be causing the "loading unit 1" issue:

```bash
chmod +x tools/check-deferred-loading.sh
./tools/check-deferred-loading.sh
```

This will identify if deferred loading is used in your app, which requires special handling.

### 3. Format your OTel Stack Traces

If you're pulling stack traces from OTel, they might need formatting to work with Flutter's symbolizer:

```bash
chmod +x tools/format-otel-stack-trace.sh
./tools/format-otel-stack-trace.sh path/to/your/otel-stack-trace.txt
```

This script formats the stack trace into what Flutter's symbolizer expects.

## Understanding Flutter Stack Trace Format

For symbolization to work, Flutter needs a specific stack trace format. Here's the minimum required:

```
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 12345, tid: 12345, name thread-name
os: android
arch: arm64
build_id: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
#00 abs 00000XXXXXXXXXX virt 00000XXXXXXXXXX _kDartIsolateSnapshotInstructions+0xXXXXXX
```

Your OTel trace might need to be formatted to match this structure.

## Rebuilding with Better Debug Symbols

If you're still having issues, try rebuilding your app with more explicit debug symbol generation:

1. Edit `build_android_release.sh` to add the `--obfuscate` flag:

```bash
flutter build apk --release --split-debug-info="$SYMBOLS_DIR/android" --obfuscate
```

2. For apps with deferred loading, ensure all loading units are properly included in debug symbols:

```bash
flutter build apk --release --split-debug-info="$SYMBOLS_DIR/android" --obfuscate --target-platform android-arm,android-arm64
```

## Alternative: Manual Symbolization

If Flutter's symbolizer continues to fail, you can try using Android NDK tools directly:

1. Install Android NDK
2. Use `ndk-stack` to process the trace:

```bash
$ANDROID_NDK_HOME/ndk-stack -sym ./debug-symbols/wonderous_opentelemetry__LATEST/android -dump ./tools/release-android-stack-trace.txt
```

## Next Steps

1. Try the fixed scripts provided
2. If still failing, check for deferred loading
3. Ensure your stack trace format matches what Flutter expects
4. Rebuild with better debug symbol configuration if necessary

Remember: The key to successful symbolization is having correctly formatted stack traces and properly generated debug symbols that include all loading units used by your app.
