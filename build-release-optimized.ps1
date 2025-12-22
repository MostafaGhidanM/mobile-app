# Optimized Release Build Script for Flutter
# This script builds a release APK with maximum size optimizations

Write-Host "Building optimized release APK..." -ForegroundColor Green

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build with optimizations
Write-Host "Building release APK with optimizations..." -ForegroundColor Yellow
Write-Host "Using flags: --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols" -ForegroundColor Cyan

flutter build apk --release `
    --split-per-abi `
    --obfuscate `
    --split-debug-info=build/app/outputs/symbols `
    --target-platform android-arm,android-arm64,android-x64

Write-Host "`nBuild completed!" -ForegroundColor Green
Write-Host "APK files location: build/app/outputs/flutter-apk/" -ForegroundColor Cyan
Write-Host "`nTo build a single universal APK (larger size), use:" -ForegroundColor Yellow
Write-Host "  flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols" -ForegroundColor White
