# AppIndex - Tax Management App

A Flutter app for managing tax readings and property searches, integrated with the `mateib.ro` API.

## What it does

- **Search Properties** - Find properties by location, street, house number, or role
- **Manage Tax Readings** - Add and manage meter readings for electricity, gas, water, etc.
- **User Authentication** - Secure login system
- **Location Services** - GPS-based auto-fill for search fields

## Installation

1. Clone the repository
   ```bash
   git clone https://github.com/gabibere/AppIndex.git
   cd AppIndex
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the app
   ```bash
   flutter run
   ```

## Building for Release

```bash
flutter build apk --release
```

## Configuration

The app connects to `https://mateib.ro` API. Configuration is in `lib/config/app_config.dart`.

## Author

**Gabriel Bere** - [GitHub](https://github.com/gabibere)