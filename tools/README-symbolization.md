# Flutter Stack Trace Symbolization Troubleshooting

The error `Failed to decode symbols file for loading unit 1` typically occurs when Flutter can't find or decode the debug symbols for a specific loading unit in your application.

## Identified Issues

1. **ZIP File Naming**: The script is using `wonderous_opentelemetry_android_symbols_.zip` but the build script creates files with version numbers.

2. **Loading Unit Issue**: The error specifically mentions "loading unit 1" which suggests deferred libraries might be involved.

3. **Stack Trace Format**: The current stack trace might be too minimal or in an unexpected format.

## Solutions to Try

### 1. Try Using the Symbols Directory Directly

Make the debug script executable and run it:

```bash
chmod +x /Users/mbushe/dev/mf/otel/wonderous_opentelemetry/tools/debug-symbolization.sh
./tools/debug-symbolization.sh
```

### 2. Ensure Stack Trace is Complete

The stack trace in `release-android-stack-trace.txt` appears truncated. Make sure it contains:
- Full exception details
- Complete stack trace with line numbers
- The `build_id` which must match the one in your debug symbols

### 3. Check for Deferred Loading

If your app uses deferred loading (with `import 'package:x/y.dart' deferred as z`), ensure your debug symbols contain information for these loading units.

### 4. Verify Symbol File Format

For Android, ensure you have:
- `app.android-arm.symbols`
- `app.android-arm64.symbols` 
- `app.android-x64.symbols`

### 5. Rebuild with Complete Debug Symbols

Try rebuilding with explicit parameters:

```bash
flutter build apk --release --split-debug-info=debug-symbols/android --obfuscate
```

### 6. Manual Symbolization Approach

If Flutter's symbolize command continues to fail, you can try using the Android NDK tools directly:

1. Install Android NDK
2. Use `ndk-stack` to process the trace:

```bash
$ANDROID_NDK_HOME/ndk-stack -sym ./debug-symbols/wonderous_opentelemetry__LATEST/android -dump ./tools/release-android-stack-trace.txt
```

## Next Steps

After making these changes, try running the symbolization again. If issues persist, consider:

1. Adding more verbose logs to your app to capture more detailed crash information
2. Checking Flutter's GitHub issues for similar problems
3. Ensuring your Flutter version is compatible with the symbolization tools
