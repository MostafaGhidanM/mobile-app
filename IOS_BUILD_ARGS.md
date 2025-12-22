# iOS Build Arguments for Codemagic

## Recommended Build Arguments

For iOS builds in Codemagic, you can use optimization arguments similar to Android:

### Recommended: Simple Release Build
**In Codemagic UI - iOS Build Arguments:**
```
--release
```

**Or in codemagic.yaml (already configured):**
```yaml
flutter build ipa --release
```

### Optional: With Obfuscation (If Needed)
**Note:** Obfuscation can cause build errors. Only use if you specifically need it.
**In Codemagic UI - iOS Build Arguments:**
```
--release --obfuscate --split-debug-info=./symbols
```

## What Each Argument Does

| Argument | Effect | Size Reduction |
|----------|--------|----------------|
| `--release` | Release build (optimized) | 20-30% |
| `--obfuscate` | Obfuscates Dart code | 10-20% |
| `--split-debug-info=./symbols` | Separates debug symbols | 5-10MB |

## Important Notes

### Differences from Android

1. **No `--split-per-abi`**: iOS doesn't support this because:
   - All iOS devices use ARM architecture
   - No need to split by CPU type
   - Single IPA file for all devices

2. **IPA Format**: iOS builds create `.ipa` files (not APK)
   - IPA = iOS App Store Package
   - Contains the app bundle
   - Already optimized by Apple's App Store

3. **Code Signing Required**: 
   - iOS builds require code signing
   - Must configure certificates in Codemagic
   - Different from Android (which can use debug keys)

## Current Configuration

The `codemagic.yaml` file is configured with:
```yaml
flutter build ipa --release
```

This gives you:
- ✅ Optimized release build
- ✅ Smaller app size (20-30% reduction)
- ✅ Stable and reliable builds

**Note:** Obfuscation is disabled to avoid build errors. You can add it later if needed.

## Expected Size Reduction

| Configuration | Size Before | Size After | Reduction |
|---------------|-------------|------------|-----------|
| Debug build | ~80-100MB | - | - |
| Release (current config) | ~80-100MB | ~50-70MB | 20-40% |
| Release + obfuscate | ~80-100MB | ~40-60MB | 40-50% (may cause errors) |

Note: Actual sizes vary based on your app's content and dependencies.

## Using in Codemagic UI

If you're using Codemagic UI (not YAML), add these arguments in the **Build arguments** field:

**For iOS (Recommended):**
```
--release
```

**For iOS (With Obfuscation - may cause errors):**
```
--release --obfuscate --split-debug-info=./symbols
```

## Troubleshooting

### Build Fails with Obfuscation
- Try without obfuscation first: `--release`
- Check if all dependencies support obfuscation
- Some packages may need keep rules

### Debug Symbols Not Found
- Ensure `--split-debug-info=./symbols` path is correct
- Check artifacts include `build/ios/**/symbols/**`

### Code Signing Errors
- Configure certificates in Codemagic
- Ensure provisioning profile matches bundle ID
- Check certificate expiration dates

## Summary

✅ **Already configured in codemagic.yaml** with `--release` (stable option)
✅ **No extra arguments needed** if using YAML workflow
✅ **If using UI workflow**, add: `--release` (simple and reliable)
⚠️ **Obfuscation disabled** to avoid build errors - can be added later if needed

The iOS build is configured for stable, optimized releases!
