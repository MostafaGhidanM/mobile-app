# iOS Build Troubleshooting - No IPA File

## Why You Can't Find the .ipa File

The `.ipa` file requires **code signing** to be configured. If code signing is not set up, the build will fail or create a `.app` bundle instead of an `.ipa` file.

## Solutions

### Solution 1: Build .app Bundle Instead (For Testing)

If you don't have code signing set up yet, you can build a `.app` bundle that can be installed via Xcode:

**Update codemagic.yaml:**
```yaml
      - name: Build iOS app
        script: |
          flutter build ios --release --no-codesign
```

This creates a `.app` bundle at: `build/ios/iphoneos/Runner.app`

**To install .app on iPhone:**
1. Open Xcode
2. Window → Devices and Simulators
3. Connect your iPhone
4. Drag `Runner.app` to the device

### Solution 2: Configure Code Signing (For IPA)

To build an `.ipa` file, you need:

1. **Apple Developer Account** ($99/year)
2. **Code Signing Certificate** (.p12 file)
3. **Provisioning Profile** (.mobileprovision file)

**Steps:**
1. Go to Codemagic → Your App → Code signing
2. Upload your certificate and provisioning profile
3. The build will then create an `.ipa` file

### Solution 3: Build for Simulator (No Code Signing Needed)

For testing on iOS Simulator (Mac only):

```yaml
      - name: Build iOS app for simulator
        script: |
          flutter build ios --release --simulator
```

This creates: `build/ios/iphonesimulator/Runner.app`

## Current Issue

Your current configuration uses:
```yaml
flutter build ipa --release
```

This **requires code signing**. If code signing is not configured, the build will fail or not produce an IPA.

## Quick Fix: Build .app Bundle

Change the build script in `codemagic.yaml` to:

```yaml
      - name: Build iOS app
        script: |
          flutter build ios --release --no-codesign
```

Then update artifacts:
```yaml
    artifacts:
      - build/ios/iphoneos/Runner.app
      - build/ios/**/symbols/**
```

## Alternative: Use Xcode Archive

If you have access to a Mac with Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Product → Archive
3. This will create an `.ipa` file (if code signing is configured)

## Summary

**Problem:** `.ipa` file requires code signing
**Quick Solution:** Build `.app` bundle with `--no-codesign`
**Proper Solution:** Set up code signing in Codemagic
**For Testing:** Use `.app` bundle with Xcode
