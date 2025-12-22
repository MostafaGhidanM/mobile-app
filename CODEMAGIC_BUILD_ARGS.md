# Codemagic Build Arguments Guide

## Safe Build Arguments for Codemagic

Based on your Codemagic setup, here are the correct build arguments to use:

### Option 1: Basic Optimization (Safest - Recommended)
**Android Build Arguments (second field):**
```
--obfuscate --split-debug-info=./symbols --split-per-abi
```

**Why this works:**
- `--obfuscate`: Obfuscates Dart code (reduces size by 10-20%)
- `--split-debug-info=./symbols`: Required with obfuscate, stores debug symbols separately
- `--split-per-abi`: Creates separate APKs per architecture (reduces each APK by 40-50%)
- Uses relative path `./symbols` which works in Codemagic

### Option 2: Using Codemagic Build Directory (Alternative)
**Android Build Arguments (second field):**
```
--obfuscate --split-debug-info=$CM_BUILD_DIR/symbols --split-per-abi
```

**Note:** `$CM_BUILD_DIR` is Codemagic's build directory variable. If this doesn't work, use Option 1 with `./symbols`.

### Option 3: Without Split (Single Universal APK)
**Android Build Arguments (second field):**
```
--obfuscate --split-debug-info=./symbols
```

This creates a single APK but still reduces size through obfuscation. Note: `--split-debug-info` is required when using `--obfuscate`.

## How to Add in Codemagic UI

1. **Mode**: Select "Release" (you already have this)
2. **Android Build Arguments**:
   - First field (dropdown): Keep `--release` selected
   - Second field: Add one of the options above (without the `--release` part, as it's already in the first field)

## Important Notes

### Why Your Previous Build Corrupted

The issue was likely:
1. **Path problem**: `--split-debug-info=build/app/outputs/symbols` uses a relative path that might not exist in Codemagic's build environment
2. **Argument conflicts**: Multiple arguments might have been parsed incorrectly
3. **Missing separator**: Codemagic might need arguments in a specific format

### What Each Argument Does

| Argument | Effect | Size Reduction |
|----------|--------|----------------|
| `--obfuscate` | Obfuscates Dart code | 10-20% |
| `--split-per-abi` | Creates separate APKs per CPU | 40-50% per APK |
| `--split-debug-info` | Separates debug symbols | 5-10MB |

### Already Enabled in Your Code

These optimizations are already enabled in your `build.gradle.kts`:
- ✅ Code minification (`isMinifyEnabled = true`)
- ✅ Resource shrinking (`isShrinkResources = true`)
- ✅ ProGuard obfuscation (automatic with minification)

So you're already getting 20-30% size reduction from Android optimizations!

## Expected Results

| Configuration | APK Size | Notes |
|---------------|----------|-------|
| No optimization | ~50MB | Original size |
| With `--obfuscate` only | ~35-40MB | Single universal APK |
| With `--obfuscate --split-per-abi` | ~15-25MB each | Separate APKs per architecture |

## Troubleshooting

### If Build Still Fails

1. **Try without obfuscation**: `--split-per-abi` (no obfuscate, but still splits APKs)
2. **Check Codemagic logs** for specific error messages
3. **Try different debug info path**: `--split-debug-info=$CM_BUILD_DIR/symbols` or `--split-debug-info=symbols`
4. **Note**: `--obfuscate` REQUIRES `--split-debug-info` - you cannot use obfuscate without it

### Alternative: Use AAB Instead

If APK builds are problematic, try building an AAB (Android App Bundle):
- **Build arguments**: `--obfuscate`
- AAB is smaller and Google Play optimizes it further
- Required for Google Play Store anyway

## Recommended Setup

**For Production Builds:**
```
Mode: Release
Android Build Arguments (second field): --obfuscate --split-debug-info=./symbols --split-per-abi
```

**Important:** Flutter requires `--split-debug-info` when using `--obfuscate`. The path `./symbols` is a relative path that works in Codemagic's build environment.

This gives you:
- ✅ Maximum size reduction
- ✅ Separate optimized APKs per architecture
- ✅ No path dependencies
- ✅ Works reliably in Codemagic
