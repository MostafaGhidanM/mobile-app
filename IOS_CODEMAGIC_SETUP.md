# iOS Build Configuration for Codemagic

## ✅ What Has Been Configured

### 1. iOS Project Structure
- ✅ Created iOS folder with all necessary files
- ✅ Updated `Info.plist` with app name "Alfa Green"
- ✅ Configured app icons for iOS
- ✅ Configured splash screen for iOS

### 2. Codemagic Configuration
- ✅ Added iOS workflow to `codemagic.yaml`
- ✅ Configured build scripts for iOS
- ✅ Set up artifact collection for IPA files

### 3. App Configuration
- ✅ App name set to "Alfa Green" in iOS Info.plist
- ✅ App icons generated from your logo
- ✅ Splash screen configured

## 📱 iOS Workflow in Codemagic

The iOS workflow in `codemagic.yaml` includes:

1. **Environment Setup**
   - Uses macOS M1 instance
   - Flutter stable version
   - Latest Xcode

2. **Build Steps**
   - Get Flutter dependencies
   - Install CocoaPods dependencies
   - Set up code signing
   - Build iOS app (IPA)

3. **Artifacts**
   - IPA files
   - Build logs

## 🔐 Code Signing Setup (Required for App Store)

To build for App Store distribution, you need to configure code signing in Codemagic:

### Option 1: Using Codemagic UI
1. Go to your app settings in Codemagic
2. Navigate to "Code signing identities"
3. Upload your:
   - **Certificate** (.p12 file)
   - **Provisioning Profile** (.mobileprovision file)

### Option 2: Using Environment Variables
Uncomment and configure in `codemagic.yaml`:
```yaml
code_signing:
  - certificate_credential: CM_CERTIFICATE
    provisioning_profile_credential: CM_PROVISIONING_PROFILE
```

Then add these as environment variables in Codemagic UI.

## 🚀 Building iOS App

### For Testing (Ad Hoc Build)
The current configuration builds a release IPA. For testing:
- You can use TestFlight
- Or configure for ad-hoc distribution

### Build Arguments
In Codemagic UI, for iOS build arguments, you can use:
```
--release
```

Or for obfuscation (like Android):
```
--release --obfuscate --split-debug-info=./symbols
```

## 📝 Important Notes

1. **Bundle Identifier**: Currently set to default. Update in:
   - `ios/Runner.xcodeproj/project.pbxproj`
   - Or via Xcode

2. **Minimum iOS Version**: Check `ios/Podfile` for minimum iOS version

3. **Permissions**: If your app needs permissions (camera, photos, etc.), add them to `ios/Runner/Info.plist`

4. **App Store Connect**: For App Store distribution, you'll need:
   - Apple Developer account ($99/year)
   - App Store Connect setup
   - Code signing certificates

## 🔧 Troubleshooting

### Build Fails with "Code signing required"
- Set up code signing certificates in Codemagic
- Or use automatic code signing (if available)

### Pod Install Fails
- Check internet connectivity in Codemagic
- Verify CocoaPods version compatibility

### Missing Permissions
- Add required permissions to `Info.plist`
- Example for camera:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>We need access to your camera to take photos</string>
  ```

## 📦 Next Steps

1. **Test the Build**: Run the iOS workflow in Codemagic
2. **Configure Code Signing**: Set up certificates for App Store
3. **Update Bundle ID**: Change from default to your unique identifier
4. **Add Permissions**: If your app needs camera, location, etc.

## 🎯 Current Status

✅ iOS project created
✅ Codemagic workflow configured
✅ App name set to "Alfa Green"
✅ Icons and splash screen configured
⏳ Code signing (needs your certificates)
⏳ Bundle identifier (needs update)

The iOS build should now work in Codemagic! You may need to configure code signing depending on your distribution method.
