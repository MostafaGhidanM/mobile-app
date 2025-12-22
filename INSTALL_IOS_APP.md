# How to Install iOS App on iPhone

## Current Situation

The build creates a **`.app` bundle** (not `.ipa`) because code signing is not configured. This is fine for testing!

## File Location

After build, you'll find:
```
Runner.app (or Runner.app.zip)
```
Location: `build/ios/iphoneos/Runner.app`

## Installation Methods

### Method 1: Using Xcode (Easiest - Mac Required)

1. **Download the `.app` file** from Codemagic artifacts
2. **Open Xcode** on your Mac
3. **Connect your iPhone** via USB
4. **Open Xcode → Window → Devices and Simulators**
5. **Select your iPhone** from the left sidebar
6. **Drag and drop** the `Runner.app` file onto the "Installed Apps" section
7. The app will install on your iPhone!

### Method 2: Convert .app to .ipa (For Distribution)

If you need an `.ipa` file:

1. **Create a folder** named `Payload`
2. **Copy** `Runner.app` into the `Payload` folder
3. **Zip** the `Payload` folder
4. **Rename** the zip file to `Runner.ipa`

**Note:** This `.ipa` will still need code signing to install on a device.

### Method 3: Use TestFlight (Requires Code Signing)

To use TestFlight, you need:
1. Apple Developer Account ($99/year)
2. Code signing certificates
3. Upload `.ipa` to App Store Connect

## Why No .ipa File?

**`.ipa` files require code signing**, which needs:
- Apple Developer Account
- Code Signing Certificate
- Provisioning Profile

**`.app` bundles** can be built without code signing and installed via Xcode.

## Quick Solution: Use .app Bundle

The current build configuration creates a `.app` bundle that you can:
- ✅ Install via Xcode (easiest)
- ✅ Test on your iPhone
- ✅ Use for development/testing

## To Get .ipa File (Future)

When you're ready for App Store or TestFlight:

1. **Get Apple Developer Account** ($99/year)
2. **Create certificates** in Apple Developer Portal
3. **Configure code signing** in Codemagic:
   - Go to Codemagic → Your App → Code signing
   - Upload certificate (.p12) and provisioning profile
4. **Change build command** back to:
   ```yaml
   flutter build ipa --release
   ```

## Summary

**Current:** Build creates `.app` bundle (no code signing needed)
**Install:** Use Xcode to drag and drop `.app` to iPhone
**Future:** Set up code signing to get `.ipa` for App Store/TestFlight

The `.app` bundle works perfectly for testing on your iPhone via Xcode!
