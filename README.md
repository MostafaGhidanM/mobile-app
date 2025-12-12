# Flutter Recycling Unit Mobile App

A Flutter mobile application for recycling units to manage their daily operations including receiving shipments, registering senders and cars, and viewing shipment history.

## Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (included with Flutter)
- Android Studio / Xcode (for mobile development)
- An Android device/emulator or iOS simulator

## Setup

1. **Install Flutter** (if not already installed):
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Verify Flutter installation**:
   ```bash
   flutter doctor
   ```

3. **Install dependencies**:
   ```bash
   cd mobile-app
   flutter pub get
   ```

## Running the App

### Option 1: Using PowerShell Script (Windows)
```powershell
cd mobile-app
.\start-app.ps1
```

### Option 2: Manual Commands
```bash
cd mobile-app
flutter pub get
flutter devices
flutter run
```

### Option 3: Run on Specific Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Configuration

### API Base URL

The app uses environment variables for the API base URL. By default, it's set to `http://localhost:3000`.

To change the API base URL, you can:

1. **Set environment variable when running**:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://your-backend-url:3000
   ```

2. **Or modify** `lib/core/utils/constants.dart`:
   ```dart
   static const String baseUrl = 'http://your-backend-url:3000';
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/                     # Core functionality
│   ├── api/                  # API client and endpoints
│   ├── models/               # Data models
│   ├── services/             # Business logic services
│   ├── theme/                # App theme
│   └── utils/                # Utilities
├── features/                 # Feature modules
│   ├── auth/                 # Authentication
│   ├── dashboard/            # Dashboard/home
│   ├── shipments/            # Shipment management
│   ├── senders/              # Sender registration
│   ├── cars/                 # Car registration
│   └── settings/             # Settings
├── widgets/                  # Reusable widgets
└── localization/             # Translations (AR/EN)
```

## Features

- ✅ Authentication (Login with phone & password)
- ✅ Dashboard with quick actions
- ✅ Shipment management (List, Receive, View)
- ✅ Sender registration (Multi-step form)
- ✅ Car registration (Multi-step form with OCR instructions)
- ✅ Settings screen
- ✅ Full Arabic/English localization
- ✅ RTL support

## Troubleshooting

### Flutter not found
- Ensure Flutter is installed and added to your PATH
- Restart your terminal after adding Flutter to PATH
- Run `flutter doctor` to verify installation

### Dependencies issues
```bash
flutter clean
flutter pub get
```

### Build issues
```bash
flutter clean
flutter pub get
flutter run
```

## Development

The app connects to the Next.js backend API. Make sure the backend is running before testing API functionality.

Default API endpoint: `http://localhost:3000/api`

## Notes

- The app uses a blue/teal color scheme (different from the reference green design)
- Full RTL support for Arabic
- Image uploads are compressed before sending to reduce bandwidth
- All API calls include Bearer token authentication




