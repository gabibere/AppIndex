# AppIndex - Flutter Tax Management Application

A modern Flutter application for tax management and meter reading, designed to integrate with the `mateib.ro` API system.

## 🚀 Features

- **User Authentication** - Secure login with encrypted credentials
- **Property Search** - Search for properties by location, street, house number, and role
- **Tax Management** - View and manage tax readings for properties
- **Meter Reading** - Add new meter readings with different reading types
- **Location Services** - GPS-based location detection and auto-fill
- **Multi-language Support** - Romanian localization
- **Modern UI** - Material 3 design with smooth animations
- **Production Ready** - Network security configuration and error handling

## 📱 Screenshots

*Screenshots will be added here*

## 🛠️ Technical Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **HTTP Client**: Dio
- **Encryption**: AES-256-CBC, MD5
- **Storage**: SharedPreferences, Flutter Secure Storage
- **Location**: Geolocator
- **UI**: Material 3

## 📋 Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Git

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/gabibere/AppIndex.git
   cd AppIndex
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### API Configuration

The app is configured to work with the `mateib.ro` API. Configuration can be found in `lib/config/app_config.dart`:

```dart
// API Configuration
static const String baseUrl = 'https://mateib.ro';
static const bool isProduction = true;
static const bool useMockData = false;
```

### Network Security

For Android, the app includes network security configuration to allow HTTPS connections to `mateib.ro`:

- **File**: `android/app/src/main/res/xml/network_security_config.xml`
- **Manifest**: `android/app/src/main/AndroidManifest.xml`

## 📡 API Endpoints

The application integrates with three main API endpoints:

### 1. Authentication - `/idexauth.php`
- **Purpose**: User login and authentication
- **Method**: POST
- **Response**: Session token, user ID, JWT token, localities

### 2. Role Search - `/idexroluri.php`
- **Purpose**: Search for properties and roles
- **Method**: POST
- **Parameters**: Location ID, street, house number, role
- **Response**: List of matching properties with tax information

### 3. Add Reading - `/idexadauga.php`
- **Purpose**: Add new meter readings
- **Method**: POST
- **Parameters**: Role ID, tax type, values, reading date
- **Response**: Success/error confirmation

## 🏗️ Project Structure

```
lib/
├── config/           # App configuration
├── models/           # Data models
├── providers/        # State management
├── screens/          # UI screens
├── services/         # API and business logic
├── widgets/          # Reusable UI components
└── utils/            # Utility functions
```

## 🔐 Security Features

- **Password Encryption**: MD5 hashing for API authentication
- **Data Encryption**: AES-256-CBC for sensitive data
- **JWT Token Handling**: Secure token management
- **Device UUID**: Unique device identification
- **Network Security**: HTTPS-only connections with certificate handling

## 📱 Device UUID Configuration

For specific releases that require a static device UUID:

1. Open `lib/services/device_service.dart`
2. Uncomment the line in `getDeviceIdentifier()` method:
   ```dart
   return 'da8a0b2aeba431afb40740415fe079b0';
   ```
3. Comment out the production/development logic below it
4. Build and deploy the release

## 🎨 UI Components

- **SearchSection**: Property search interface
- **ResultsSection**: Display search results
- **WorkModal**: Tax reading management
- **LocationDropdown**: Location selection
- **ReadingDateCard**: Global reading date picker

## 🌍 Localization

The app supports Romanian language with localization files in:
- `assets/l10n/ro.json`
- `lib/services/localization_service.dart`

## 🚀 Building for Production

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🐛 Debugging

The app includes comprehensive logging through `DebugLogger`:

```dart
DebugLogger.api('API call details');
DebugLogger.search('Search operations');
DebugLogger.location('Location services');
DebugLogger.error('Error messages');
```

## 📝 Reading Types

The application supports five reading types:

- **C - Citire**: Manual reading (default)
- **E - Estimată**: Estimated reading
- **P - Paușală**: Fixed reading
- **F - Fără facturare**: No billing reading
- **X - Neutilizat**: Unused reading

## 🔄 State Management

The app uses Provider for state management:

- **AuthProvider**: User authentication and session
- **SearchProvider**: Search results and operations
- **LocationProvider**: GPS and location services
- **ReadingDateProvider**: Global reading date management

## 📊 Data Models

Key data models include:

- **User**: User information and authentication
- **Role**: Property role with person and address details
- **Tax**: Tax information with readings and values
- **Locality**: Location data for dropdowns

## 🛡️ Error Handling

Comprehensive error handling for:

- Network connectivity issues
- API response errors
- Location permission denials
- Authentication failures
- Data validation errors

## 📱 Platform Support

- ✅ **Android** (Primary target)
- ✅ **iOS**
- ✅ **Web**
- ✅ **Windows**
- ✅ **macOS**
- ✅ **Linux**

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Gabriel Bere**
- GitHub: [@gabibere](https://github.com/gabibere)
- Repository: [AppIndex](https://github.com/gabibere/AppIndex)

## 📞 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the documentation in the `lib/docs/` folder

## 🔄 Version History

- **v1.0.0** - Initial release with complete API integration
  - User authentication
  - Property search functionality
  - Tax reading management
  - Production-ready configuration

---

**Built with ❤️ using Flutter**