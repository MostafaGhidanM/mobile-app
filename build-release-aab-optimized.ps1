# Optimized Release Build Script for Android App Bundle (AAB)
# AAB format is required for Google Play Store and allows Google to optimize APKs per device

Write-Host "Building optimized release Android App Bundle (AAB)..." -ForegroundColor Green

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build AAB with optimizations
Write-Host "Building release AAB with optimizations..." -ForegroundColor Yellow
Write-Host "Using flags: --release --obfuscate --split-debug-info=build/app/outputs/symbols" -ForegroundColor Cyan

flutter build appbundle --release `
    --obfuscate `
    --split-debug-info=build/app/outputs/symbols

Write-Host "`nBuild completed!" -ForegroundColor Green
Write-Host "AAB file location: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Cyan
Write-Host "`nNote: AAB format is smaller and optimized by Google Play Store" -ForegroundColor Yellow
