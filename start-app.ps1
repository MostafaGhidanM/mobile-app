# Flutter Recycling Unit App Startup Script
Write-Host "Starting Flutter Recycling Unit App..." -ForegroundColor Green

# Check if Flutter is available
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue

if (-not $flutterPath) {
    Write-Host "Flutter is not found in PATH. Please ensure Flutter is installed and added to your PATH." -ForegroundColor Red
    Write-Host "You can download Flutter from: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternatively, you can run these commands manually:" -ForegroundColor Yellow
    Write-Host "  cd mobile-app" -ForegroundColor Cyan
    Write-Host "  flutter pub get" -ForegroundColor Cyan
    Write-Host "  flutter devices" -ForegroundColor Cyan
    Write-Host "  flutter run" -ForegroundColor Cyan
    exit 1
}

# Navigate to mobile-app directory
Set-Location $PSScriptRoot

# Get dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install dependencies. Please check your Flutter installation." -ForegroundColor Red
    exit 1
}

# Check for available devices
Write-Host "Checking for available devices..." -ForegroundColor Yellow
flutter devices

# Run the app
Write-Host "Starting the app..." -ForegroundColor Green
flutter run




