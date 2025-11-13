class AppConfig {
  // App Information
  static const String appName = 'SysIndex';
  static const String appVersion = '1.0.0';

  // Colors - Modern Color Palette
  static const int primaryColor = 0xFF6366F1; // Indigo
  static const int secondaryColor = 0xFF8B5CF6; // Purple
  static const int accentColor = 0xFF06B6D4; // Cyan
  static const int successColor = 0xFF10B981; // Emerald
  static const int warningColor = 0xFFF59E0B; // Amber
  static const int errorColor = 0xFFEF4444; // Red
  static const int backgroundColor = 0xFFF8FAFC; // Slate 50
  static const int surfaceColor = 0xFFFFFFFF; // White
  static const int textColor = 0xFF1E293B; // Slate 800
  static const int textSecondaryColor = 0xFF64748B; // Slate 500

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // API Configuration
  static const String baseUrl = 'https://mateib.ro';
  static const Duration apiTimeout = Duration(seconds: 30);

  // API Endpoints
  static const String authEndpoint = '/idexauth.php';

  // Security Configuration
  static const bool enableEncryption = true;
  static const bool logApiCalls = true;
  static const bool logJwtAndSession = true;
  static const String passEncript5 = 'syscasa';

  // Production Settings
  static const bool isProduction = true;
  static const bool isDevelopment = false;

  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String searchHistoryKey = 'search_history';
  static const String settingsKey = 'app_settings';

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  // Debug Settings
  static const bool showDebugInfo = false;
  static const bool enableAnimations = true;

  // Mock Data Settings
  static const bool useMockData = false;
  static const bool enableMockAuth = false;
}
