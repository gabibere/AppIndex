# SysIndex

A modern Flutter application for managing property indexes and utility meter readings. Built with beautiful animations, intuitive UX, and seamless integration with the mateib.ro API.

## Overview

SysIndex simplifies the management of property records and utility meter readings. Whether you're searching for properties, recording meter readings, or managing tax information, the app provides a streamlined experience with a modern, user-friendly interface.

## How It Works

### 🔐 Authentication Flow

The app starts with a secure authentication system:

1. **Splash Screen** - Initializes the app and checks for existing authentication
2. **Login** - Users authenticate with username and password
3. **Session Management** - Secure token-based sessions are maintained throughout the app
4. **Auto-login** - Previously authenticated sessions are automatically restored

Authentication credentials are encrypted and securely stored on the device. The app communicates with the mateib.ro API using encrypted requests and maintains session tokens for subsequent API calls.

### 🏠 Property Search

The core functionality revolves around searching and managing properties:

**Search Capabilities:**
- **Location-based search** - Filter properties by locality
- **Street search** - Find properties by street name
- **House number lookup** - Search by specific house numbers
- **Role-based filtering** - Filter by property roles and types

**Search Process:**
1. Select a locality from the dropdown (populated from your account's available locations)
2. Enter street name, house number, or role information
3. The app queries the API and displays matching properties
4. Results are paginated for easy browsing
5. Tap any property to view detailed information and manage readings

**Location Services:**
- GPS integration for automatic location detection
- Smart location dropdown with distinct localities
- Location data extracted from authentication tokens

### 📊 Meter Reading Management

Manage utility meter readings with ease:

**Reading Types:**
- **Electricity** - Record electricity meter readings
- **Gas** - Track gas consumption
- **Water** - Monitor water usage
- **Other utilities** - Support for various tax types

**Reading Workflow:**
1. Select a property from search results
2. View available tax types and meter information
3. Enter new meter readings with date selection
4. Choose reading type (New, Estimated, Previous)
5. Save readings directly to the server
6. View historical reading data

**Date Management:**
- Smart date picker for reading dates
- Automatic date validation
- Support for different reading types (P, E, N)

### 🎨 User Interface

**Modern Design:**
- Clean, minimalist interface with Material Design 3
- Smooth animations and transitions
- Glassmorphism effects for modern aesthetics
- Responsive layout that adapts to different screen sizes

**Color Scheme:**
- Primary: Indigo (#6366F1)
- Secondary: Purple (#8B5CF6)
- Accent: Cyan (#06B6D4)
- Success, Warning, and Error states with appropriate colors

**User Experience:**
- Intuitive navigation with smooth page transitions
- Loading states with shimmer effects
- Error handling with user-friendly messages
- Keyboard-aware layouts
- Pull-to-refresh functionality

### 🔧 Technical Architecture

**State Management:**
- Provider pattern for reactive state management
- Separate providers for authentication, search, location, and reading dates
- Efficient state updates with minimal rebuilds

**API Integration:**
- RESTful API communication with mateib.ro
- Encrypted request/response handling
- JWT token extraction and management
- Session token persistence
- Comprehensive error handling

**Local Storage:**
- Secure storage for authentication tokens
- Shared preferences for user settings
- SQLite database for offline data caching
- Search history preservation

**Services:**
- **API Service** - Centralized API communication
- **Encryption Service** - Password hashing and data encryption
- **JWT Service** - Token generation and parsing
- **Location Service** - GPS and geocoding integration
- **Localization Service** - Multi-language support (Romanian)
- **Error Handling Service** - User-friendly error messages

### 🌍 Localization

The app supports Romanian language with:
- Localized strings for all UI elements
- Date and number formatting
- Error messages in Romanian
- Cultural date/time formats

### 🔒 Security Features

- **Password Encryption** - MD5 hashing for secure authentication
- **Secure Storage** - Encrypted local storage for sensitive data
- **Session Management** - Secure token-based sessions
- **API Encryption** - Encrypted communication with the server
- **Device Identification** - Unique device ID for authentication

### 📱 Platform Support

Built with Flutter for cross-platform compatibility:
- **Android** - Full feature support
- **iOS** - Native iOS experience
- **Web** - Browser-based access
- **Windows** - Desktop application
- **macOS** - Native macOS support
- **Linux** - Linux desktop support

## App Structure

```
lib/
├── config/          # App configuration and constants
├── models/          # Data models (User, Property, Tax, etc.)
├── providers/       # State management providers
├── screens/         # Main app screens (Login, Dashboard, Splash)
├── services/        # Business logic services (API, Encryption, etc.)
├── widgets/         # Reusable UI components
└── utils/           # Utility functions and helpers
```

## Features

✨ **Modern UI/UX**
- Beautiful animations and transitions
- Intuitive user interface
- Responsive design
- Dark mode ready (configurable)

🔍 **Advanced Search**
- Multi-criteria property search
- Location-based filtering
- Real-time search results
- Search history

📝 **Reading Management**
- Easy meter reading entry
- Multiple reading types
- Date validation
- Historical data viewing

🔐 **Security**
- Encrypted authentication
- Secure data storage
- Session management
- Device identification

🌐 **API Integration**
- Seamless mateib.ro integration
- Error handling
- Offline capability
- Data synchronization

## Configuration

The app configuration is centralized in `lib/config/app_config.dart`, where you can customize:
- API endpoints
- Color schemes
- Animation durations
- Security settings
- UI constants

## Dependencies

The app leverages modern Flutter packages including:
- **State Management**: Provider
- **HTTP**: Dio, HTTP
- **Storage**: SharedPreferences, SQLite, Secure Storage
- **Security**: Crypto, Encrypt
- **Location**: Geolocator, Geocoding
- **UI**: Lottie, Shimmer, Glassmorphism
- **Utilities**: Intl, Connectivity Plus

---
