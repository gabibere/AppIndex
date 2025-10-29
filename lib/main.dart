import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/search_provider.dart';
import 'providers/location_provider.dart';
import 'providers/reading_date_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/localization_service.dart';
import 'services/api_service.dart';
import 'utils/debug_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI for transparent navigation bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize services
  await LocalizationService.loadLanguage('ro');
  ApiService.initialize();

  runApp(const AppIndex());
}

class AppIndex extends StatelessWidget {
  const AppIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => ReadingDateProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ro', '')],
        locale: const Locale('ro', ''),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
        builder: (context, child) {
          // Global error boundary
          ErrorWidget.builder = (FlutterErrorDetails details) {
            DebugLogger.error(
              'Global error: ${details.exception}',
              error: details.exception,
              stackTrace: details.stack,
            );
            return Material(
              child: Container(
                color: const Color(AppConfig.backgroundColor),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 64),
                      SizedBox(height: 16),
                      Text('Ceva nu a mers bine'),
                      Text('Vă rugăm să reporniți aplicația'),
                    ],
                  ),
                ),
              ),
            );
          };

          // Wrap with SafeArea and keyboard dismissal functionality
          return SafeArea(
            child: GestureDetector(
              onTap: () {
                // Dismiss keyboard when tapping anywhere on the screen
                FocusScope.of(context).unfocus();
              },
              child: child!,
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConfig.primaryColor),
        primary: const Color(AppConfig.primaryColor),
        secondary: const Color(AppConfig.secondaryColor),
        tertiary: const Color(AppConfig.accentColor),
        surface: const Color(AppConfig.surfaceColor),
        onPrimary: const Color(AppConfig.surfaceColor),
        onSecondary: const Color(AppConfig.surfaceColor),
        onSurface: const Color(AppConfig.textColor),
        error: const Color(AppConfig.errorColor),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConfig.primaryColor),
        foregroundColor: Color(AppConfig.surfaceColor),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(AppConfig.surfaceColor),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppConfig.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        color: const Color(AppConfig.surfaceColor),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConfig.primaryColor),
          foregroundColor: const Color(AppConfig.surfaceColor),
          elevation: 2,
          shadowColor: const Color(
            AppConfig.primaryColor,
          ).withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(AppConfig.primaryColor),
          side: const BorderSide(
            color: Color(AppConfig.primaryColor),
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(AppConfig.surfaceColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: Color(AppConfig.secondaryColor)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: Color(AppConfig.secondaryColor)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(
            color: Color(AppConfig.primaryColor),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: Color(AppConfig.errorColor)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: Color(AppConfig.textSecondaryColor),
          fontWeight: FontWeight.w500,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(AppConfig.textColor),
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(AppConfig.textColor),
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(AppConfig.textColor),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(AppConfig.textColor),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(AppConfig.textColor),
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Color(AppConfig.textColor)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(AppConfig.textColor)),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(AppConfig.textSecondaryColor),
        ),
      ),
    );
  }
}
