# HimiloGuul Flutter Frontend

This is the Flutter frontend application for the HimiloGuul business marketplace platform.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── config/                            # Configuration files
│   ├── app_colors.dart               # Color constants
│   └── app_theme.dart                 # Theme configuration
├── core/                              # Core functionality
│   └── widgets/                      # Reusable widgets
│       ├── abstract_header_painter.dart
│       └── feature_illustration.dart
└── presentation/                      # UI layer
    ├── routes/                        # Route definitions
    │   └── app_routes.dart
    └── screens/                       # Screen widgets
        └── welcome/
            └── welcome_screen.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Current Features

### ✅ Welcome Screen
- Abstract header graphic with custom painter
- Welcome message and description
- Three feature sections with illustrations:
  - Verified Listings
  - Direct Messaging
  - Secure Deals
- Get Started button

## Next Steps

1. Create authentication screens (Login/Register)
2. Set up navigation with go_router
3. Implement API integration
4. Create business browsing screens
5. Add profile management

## Dependencies

- `provider` - State management
- `dio` - HTTP client
- `shared_preferences` - Local storage
- `flutter_secure_storage` - Secure token storage
- `go_router` - Navigation

## Assets

Place images and other assets in the `assets/images/` folder.
