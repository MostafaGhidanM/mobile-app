# Codemagic Build Troubleshooting Guide

## Current Issue: Android SDK Build-Tools 35 Download Timeout

### Problem
The build is failing because Codemagic is trying to download Android SDK Build-Tools 35.0.0, but the download is timing out due to network issues.

### Solutions

#### Solution 1: Use codemagic.yaml (Recommended)

I've created a `codemagic.yaml` file that:
- Specifies Android Build-Tools 34.0.0 (more stable, likely already cached)
- Configures the build environment properly
- Sets up proper SDK component installation

**To use it:**
1. The `codemagic.yaml` file is already in your project root
2. In Codemagic UI, make sure you're using the YAML-based workflow
3. The build will use Build-Tools 34.0.0 instead of 35.0.0

#### Solution 2: Configure Build Tools Version in Gradle

I've also updated `android/gradle.properties` to specify build tools version 34.0.0.

#### Solution 3: Retry the Build

Sometimes network issues are temporary. Try:
1. Wait a few minutes and retry the build
2. Network connectivity in Codemagic might be temporarily slow

#### Solution 4: Use UI Configuration (If not using YAML)

If you're using Codemagic UI (not YAML), you can:

1. **In Codemagic UI, go to your app settings**
2. **Add a script before the build:**
   ```bash
   # Install specific build tools version
   sdkmanager "build-tools;34.0.0" "platforms;android-34"
   ```

3. **Or configure environment variables:**
   - Add: `ANDROID_BUILD_TOOLS_VERSION=34.0.0`

## Build Arguments (After Fixing SDK Issue)

Once the SDK download issue is resolved, use these build arguments:

### For Split APKs (Recommended):
```
--split-per-abi
```

### For Obfuscated Split APKs:
```
--obfuscate --split-debug-info=./symbols --split-per-abi
```

### For AAB (Android App Bundle):
```
--obfuscate --split-debug-info=./symbols
```

## Why Build-Tools 34.0.0 Instead of 35.0.0?

1. **More Stable**: Build-Tools 34.0.0 is more widely used and tested
2. **Likely Cached**: Codemagic likely has 34.0.0 already cached, avoiding download
3. **Compatibility**: Works with all current Android features
4. **Faster Builds**: No download wait time

## Expected Build Sizes

After fixing the SDK issue and using the build arguments:

| Configuration | APK Size |
|---------------|----------|
| `--split-per-abi` | ~15-25MB each (separate APKs) |
| `--obfuscate --split-debug-info=./symbols --split-per-abi` | ~12-20MB each |
| Universal APK (no split) | ~30-40MB |

## Next Steps

1. **Commit the `codemagic.yaml` file** to your repository
2. **In Codemagic UI**, switch to YAML-based workflow (if not already)
3. **Retry the build** - it should now use Build-Tools 34.0.0
4. **Use build arguments**: `--split-per-abi` (or with obfuscation if needed)

## If Build Still Fails

1. **Check Codemagic logs** for specific error messages
2. **Verify SDK installation** in the logs
3. **Try without obfuscation first**: Just use `--split-per-abi`
4. **Contact Codemagic support** if network issues persist

## Alternative: Build Locally First

If Codemagic continues to have issues, you can:
1. Build locally to verify everything works
2. Then retry in Codemagic once network is stable
3. Use the same build arguments locally: `flutter build apk --release --split-per-abi`
