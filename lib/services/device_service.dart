import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../utils/debug_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

/// Device Service for managing device identification and UUID generation
///
/// For specific releases that need a static device UUID:
/// 1. Uncomment the line in getDeviceIdentifier() method:
///    // return 'da8a0b2aeba431afb40740415fe079b0';
/// 2. Comment out the production/development logic below it
/// 3. Build and deploy the release
class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Get a stable device UUID that persists across app reinstalls
  static Future<String> getStableDeviceUUID() async {
    try {
      // Try to get existing UUID from secure storage
      String? existingUUID = await _secureStorage.read(key: 'device_uuid');

      if (existingUUID != null && existingUUID.isNotEmpty) {
        if (AppConfig.showDebugInfo) {
          DebugLogger.device(
              '📱 [UUID] Retrieved existing stable UUID: $existingUUID');
        }
        return existingUUID;
      }

      // Generate new UUID based on device characteristics
      final deviceFingerprint = await getDeviceFingerprint();
      final androidInfo = await _deviceInfo.androidInfo;

      // Create a unique identifier combining multiple stable characteristics
      final uuidComponents = [
        androidInfo.brand,
        androidInfo.model,
        androidInfo.manufacturer,
        androidInfo.hardware,
        androidInfo.fingerprint,
        androidInfo.id, // Android ID as additional entropy
      ].join('|');

      // Generate SHA-256 hash to create a consistent UUID
      final bytes = utf8.encode(uuidComponents);
      final digest = sha256.convert(bytes);
      final uuid = digest.toString().substring(0, 32); // Use first 32 chars

      // Store the UUID securely
      await _secureStorage.write(key: 'device_uuid', value: uuid);

      if (AppConfig.showDebugInfo) {
        DebugLogger.device('📱 [UUID] Generated new stable UUID: $uuid');
        DebugLogger.device(
            '   Based on fingerprint: ${deviceFingerprint.substring(0, 50)}...');
      }

      return uuid;
    } catch (e) {
      DebugLogger.device('Error generating stable device UUID: $e');
      return 'error_uuid_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Get the best available device UUID for your use case
  static Future<String> getBestDeviceUUID() async {
    try {
      // Priority order: Registration UUID > IMEI > Stable UUID > Android ID > Composite ID

      // Try registration UUID first (most reliable and unique)
      final registrationUUID = await getStoredDeviceRegistrationUUID();
      if (registrationUUID != null && registrationUUID.isNotEmpty) {
        if (AppConfig.showDebugInfo) {
          DebugLogger.device(
              'Using registration UUID: ${registrationUUID.substring(0, 32)}...');
        }
        return registrationUUID;
      }

      // Try IMEI second (most unique)
      final imei = await getDeviceIMEI();
      if (imei != null && imei.isNotEmpty && imei != '000000000000000') {
        if (AppConfig.showDebugInfo) {
          DebugLogger.device('📱 [BEST UUID] Using IMEI: $imei');
        }
        return imei;
      }

      // Try stable UUID (persistent across reinstalls)
      final stableUUID = await getStableDeviceUUID();
      if (AppConfig.showDebugInfo) {
        DebugLogger.device('📱 [BEST UUID] Using stable UUID: $stableUUID');
      }
      return stableUUID;
    } catch (e) {
      DebugLogger.device('Error getting best device UUID: $e');
      return 'error_uuid_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Get comprehensive device identifier with multiple options
  static Future<Map<String, String>> getDeviceIdentifiers() async {
    try {
      final Map<String, String> identifiers = {};

      // Get IMEI (if available)
      final imei = await getDeviceIMEI();
      if (imei != null) {
        identifiers['imei'] = imei;
      }

      // Get Android ID
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        identifiers['android_id'] = androidInfo.id;
      }

      // Get stable UUID
      final stableUUID = await getStableDeviceUUID();
      identifiers['stable_uuid'] = stableUUID;

      // Get device fingerprint
      final fingerprint = await getDeviceFingerprint();
      identifiers['fingerprint'] = fingerprint;

      // Get composite device ID
      final compositeId = await _getCompositeDeviceId();
      identifiers['composite_id'] = compositeId;

      if (AppConfig.showDebugInfo) {
        DebugLogger.device('📱 [IDENTIFIERS] Available device identifiers:');
        identifiers.forEach((key, value) {
          DebugLogger.device(
              '   $key: ${value.length > 50 ? '${value.substring(0, 50)}...' : value}');
        });
      }

      return identifiers;
    } catch (e) {
      DebugLogger.device('Error getting device identifiers: $e');
      return {
        'error': 'Failed to get device identifiers: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get composite device ID (enhanced version)
  static Future<String> _getCompositeDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        final components = [
          androidInfo.brand,
          androidInfo.model,
          androidInfo.manufacturer,
          androidInfo.device,
          androidInfo.product,
          androidInfo.hardware,
          androidInfo.version.release,
          androidInfo.version.sdkInt.toString(),
        ].where((component) => component.isNotEmpty);

        final compositeId =
            components.join('_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        return compositeId;
      } else {
        return 'unknown_platform';
      }
    } catch (e) {
      DebugLogger.device('Error getting composite device ID: $e');
      return 'error_composite_id';
    }
  }

  // Get device IMEI (Android) or device identifier
  static Future<String?> getDeviceIMEI() async {
    try {
      if (Platform.isAndroid) {
        // First try to get real IMEI
        String? realImei = await _getRealIMEI();

        if (realImei != null &&
            realImei.isNotEmpty &&
            realImei != '000000000000000') {
          if (AppConfig.showDebugInfo) {
            DebugLogger.device('📱 [REAL IMEI] Found real IMEI: $realImei');
          }
          return realImei;
        }

        // Fallback to device registration UUID if real IMEI not available
        final registrationUUID = await getStoredDeviceRegistrationUUID();
        if (registrationUUID != null && registrationUUID.isNotEmpty) {
          if (AppConfig.showDebugInfo) {
            DebugLogger.device(
                'Using device registration UUID: ${registrationUUID.substring(0, 32)}...');
          }
          return registrationUUID;
        }

        // Final fallback to composite device ID
        final androidInfo = await _deviceInfo.androidInfo;
        String? androidId = androidInfo.id;

        final deviceId = [
          androidId,
          androidInfo.brand,
          androidInfo.model,
          androidInfo.manufacturer,
          androidInfo.device,
          androidInfo.product,
        ].join('_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

        if (AppConfig.showDebugInfo) {
          DebugLogger.device(
              '📱 [FALLBACK] Using composite device ID: $deviceId');
          DebugLogger.device(
              '   Real IMEI not available (permission denied or Android 10+)');
          DebugLogger.log('   Registration UUID not available');
          DebugLogger.log('   Android ID: $androidId');
          DebugLogger.log('   Brand: ${androidInfo.brand}');
          DebugLogger.log('   Model: ${androidInfo.model}');
        }

        return deviceId;
      } else {
        return 'unknown_device';
      }
    } catch (e) {
      DebugLogger.device('Error getting device IMEI: $e');
      return null;
    }
  }

  // Get real IMEI using platform-specific code
  static Future<String?> _getRealIMEI() async {
    try {
      // Request phone state permission
      var status = await Permission.phone.request();

      if (!status.isGranted) {
        if (AppConfig.showDebugInfo) {
          DebugLogger.device('📱 [IMEI] Permission denied by user');
        }
        return null;
      }

      // Use platform channel to get IMEI
      const platform = MethodChannel('device_info');
      final String? imei = await platform.invokeMethod('getIMEI');

      if (AppConfig.showDebugInfo) {
        DebugLogger.device('📱 [IMEI] Platform channel result: $imei');
      }

      return imei;
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.device('📱 [IMEI] Error getting real IMEI: $e');
      }
      return null;
    }
  }

  // Get a more detailed device fingerprint
  static Future<String> getDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // Create a comprehensive device fingerprint
        final fingerprint = [
          androidInfo.brand,
          androidInfo.model,
          androidInfo.manufacturer,
          androidInfo.device,
          androidInfo.product,
          androidInfo.hardware,
          androidInfo.fingerprint,
          androidInfo.version.release,
          androidInfo.version.sdkInt.toString(),
        ].join('|').replaceAll(RegExp(r'[^a-zA-Z0-9_|]'), '_');

        return fingerprint;
      } else {
        return 'unknown_platform';
      }
    } catch (e) {
      DebugLogger.device('Error getting device fingerprint: $e');
      return 'error_fingerprint';
    }
  }

  // Check if device is compatible
  static Future<bool> isDeviceCompatible() async {
    if (!AppConfig.isProduction) {
      return true; // Always compatible in development
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Check Android version (minimum API 21)
        return androidInfo.version.sdkInt >= 21;
      }
      return false; // Only Android is supported
    } catch (e) {
      DebugLogger.device('Error checking device compatibility: $e');
      return false;
    }
  }

  // Get device information
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'device': androidInfo.device,
          'product': androidInfo.product,
          'hardware': androidInfo.hardware,
          'fingerprint': androidInfo.fingerprint,
          'id': androidInfo.id,
        };
      } else {
        return {
          'platform': 'Unknown',
          'error': 'Platform not supported',
        };
      }
    } catch (e) {
      return {
        'platform': 'Unknown',
        'error': e.toString(),
      };
    }
  }

  // Request necessary permissions
  static Future<bool> requestPermissions() async {
    try {
      // Request phone state permission (for IMEI)
      final phoneStatus = await Permission.phone.request();

      // Request location permission (for printer discovery)
      final locationStatus = await Permission.location.request();

      // Request storage permission (for receipt storage)
      final storageStatus = await Permission.storage.request();

      return phoneStatus.isGranted &&
          locationStatus.isGranted &&
          storageStatus.isGranted;
    } catch (e) {
      DebugLogger.log('Error requesting permissions: $e');
      return false;
    }
  }

  // Check if permissions are granted
  static Future<bool> checkPermissions() async {
    try {
      final phoneStatus = await Permission.phone.status;
      final locationStatus = await Permission.location.status;
      final storageStatus = await Permission.storage.status;

      return phoneStatus.isGranted &&
          locationStatus.isGranted &&
          storageStatus.isGranted;
    } catch (e) {
      DebugLogger.log('Error checking permissions: $e');
      return false;
    }
  }

  // Debug method to show all UUID components
  static Future<Map<String, dynamic>> getUUIDComponents() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        final components = [
          androidInfo.brand,
          androidInfo.model,
          androidInfo.manufacturer,
          androidInfo.hardware,
          androidInfo.fingerprint,
          androidInfo.id,
        ];

        final combinedString = components.join('|');
        final bytes = utf8.encode(combinedString);
        final digest = sha256.convert(bytes);
        final fullHash = digest.toString();
        final uuid = fullHash.substring(0, 32);

        return {
          'components': {
            'brand': androidInfo.brand,
            'model': androidInfo.model,
            'manufacturer': androidInfo.manufacturer,
            'hardware': androidInfo.hardware,
            'fingerprint': androidInfo.fingerprint,
            'android_id': androidInfo.id,
          },
          'combined_string': combinedString,
          'full_hash': fullHash,
          'stable_uuid': uuid,
          'component_count': components.length,
          'string_length': combinedString.length,
        };
      } else {
        return {
          'error': 'Platform not supported',
          'platform': 'non-android',
        };
      }
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Generate and store a unique device UUID for database registration
  static Future<Map<String, dynamic>> generateDeviceRegistrationUUID() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // Create a comprehensive device signature with additional uniqueness factors
        final deviceSignature = [
          androidInfo.brand,
          androidInfo.model,
          androidInfo.manufacturer,
          androidInfo.device,
          androidInfo.product,
          androidInfo.hardware,
          androidInfo.fingerprint,
          androidInfo.version.release,
          androidInfo.version.sdkInt.toString(),
          androidInfo.id, // Android ID for additional uniqueness
          androidInfo.version.incremental,
          androidInfo.version.securityPatch ?? '',
          androidInfo.supportedAbis.join(','),
          androidInfo.supported32BitAbis.join(','),
          androidInfo.supported64BitAbis.join(','),
        ].join('|');

        // Generate SHA-256 hash and take first 32 characters for shorter UUID
        final bytes = utf8.encode(deviceSignature);
        final digest = sha256.convert(bytes);
        final deviceUUID = digest.toString().substring(0, 32);

        // Create registration payload
        final registrationData = {
          'device_uuid': deviceUUID,
          'device_info': {
            'brand': androidInfo.brand,
            'model': androidInfo.model,
            'manufacturer': androidInfo.manufacturer,
            'device': androidInfo.device,
            'product': androidInfo.product,
            'hardware': androidInfo.hardware,
            'fingerprint': androidInfo.fingerprint,
            'android_version': androidInfo.version.release,
            'api_level': androidInfo.version.sdkInt,
            'android_id': androidInfo.id,
            'build_incremental': androidInfo.version.incremental,
            'security_patch': androidInfo.version.securityPatch,
            'supported_abis': androidInfo.supportedAbis,
            'supported_32bit_abis': androidInfo.supported32BitAbis,
            'supported_64bit_abis': androidInfo.supported64BitAbis,
          },
          'app_info': {
            'app_version': AppConfig.appVersion,
            'platform': 'Android',
            'registration_timestamp': DateTime.now().toIso8601String(),
          },
          'device_signature': deviceSignature,
          'signature_hash': deviceUUID,
        };

        // Store the UUID locally for future reference
        await _secureStorage.write(
            key: 'device_registration_uuid', value: deviceUUID);
        await _secureStorage.write(
            key: 'device_registration_data',
            value: json.encode(registrationData));

        if (AppConfig.showDebugInfo) {
          DebugLogger.device(
              '📱 [REGISTRATION] Generated unique device UUID: $deviceUUID');
          DebugLogger.log(
              '   Device: ${androidInfo.brand} ${androidInfo.model}');
          DebugLogger.device(
              '   Android: ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})');
          DebugLogger.device(
              '   Signature length: ${deviceSignature.length} characters');
        }

        return {
          'success': true,
          'device_uuid': deviceUUID,
          'registration_data': registrationData,
          'message': 'Device UUID generated successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Platform not supported',
          'platform': 'non-android',
        };
      }
    } catch (e) {
      DebugLogger.device('Error generating device registration UUID: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get stored device registration UUID
  static Future<String?> getStoredDeviceRegistrationUUID() async {
    try {
      return await _secureStorage.read(key: 'device_registration_uuid');
    } catch (e) {
      DebugLogger.device('Error getting stored device registration UUID: $e');
      return null;
    }
  }

  // Get stored device registration data
  static Future<Map<String, dynamic>?> getStoredDeviceRegistrationData() async {
    try {
      final data = await _secureStorage.read(key: 'device_registration_data');
      if (data != null) {
        return json.decode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      DebugLogger.device('Error getting stored device registration data: $e');
      return null;
    }
  }

  // Check if device is already registered
  static Future<bool> isDeviceRegistered() async {
    try {
      final uuid = await getStoredDeviceRegistrationUUID();
      return uuid != null && uuid.isNotEmpty;
    } catch (e) {
      DebugLogger.device('Error checking device registration status: $e');
      return false;
    }
  }

  // Clear device registration data (for testing or re-registration)
  static Future<void> clearDeviceRegistration() async {
    try {
      await _secureStorage.delete(key: 'device_registration_uuid');
      await _secureStorage.delete(key: 'device_registration_data');
      await _secureStorage.delete(key: 'device_uuid'); // Also clear stable UUID
      if (AppConfig.showDebugInfo) {
        DebugLogger.device(
            '📱 [REGISTRATION] Cleared device registration data');
      }
    } catch (e) {
      DebugLogger.device('Error clearing device registration: $e');
    }
  }

  // Validate device UUID format and uniqueness
  static bool isValidDeviceUUID(String uuid) {
    // Check if UUID is a valid SHA-256 hash (64 characters, hexadecimal)
    final uuidRegex = RegExp(r'^[a-fA-F0-9]{64}$');
    return uuidRegex.hasMatch(uuid);
  }

  // Get device registration status and data
  static Future<Map<String, dynamic>> getDeviceRegistrationStatus() async {
    try {
      final isRegistered = await isDeviceRegistered();
      final uuid = await getStoredDeviceRegistrationUUID();
      final data = await getStoredDeviceRegistrationData();

      return {
        'is_registered': isRegistered,
        'device_uuid': uuid,
        'registration_data': data,
        'uuid_valid': uuid != null ? isValidDeviceUUID(uuid) : false,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'is_registered': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Force regenerate UUID with new 32-character format
  static Future<Map<String, dynamic>> forceRegenerateUUID() async {
    try {
      // Clear all stored UUIDs
      await clearDeviceRegistration();

      // Generate new 32-character UUID
      final result = await generateDeviceRegistrationUUID();

      if (result['success']) {
        final newUUID = result['device_uuid'];
        if (AppConfig.showDebugInfo) {
          DebugLogger.device(
              '📱 [FORCE REGENERATE] New 32-character UUID: $newUUID');
          DebugLogger.device(
              '📱 [FORCE REGENERATE] UUID length: ${newUUID.length} characters');
        }
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get installation UUID (generated on first app install)
  static Future<String> getInstallationUUID() async {
    try {
      // Check if UUID already exists in secure storage
      String? existingUUID =
          await _secureStorage.read(key: 'installation_uuid');

      if (existingUUID != null && existingUUID.isNotEmpty) {
        if (AppConfig.showDebugInfo) {
          DebugLogger.device(
              '📱 [INSTALLATION UUID] Retrieved existing UUID: $existingUUID');
        }
        return existingUUID;
      }

      // First installation - generate new UUID
      final newUUID = _generateRandomUUID();
      await _secureStorage.write(key: 'installation_uuid', value: newUUID);

      if (AppConfig.showDebugInfo) {
        DebugLogger.device(
            '📱 [INSTALLATION UUID] Generated new UUID on first install: $newUUID');
      }

      return newUUID;
    } catch (e) {
      DebugLogger.log('Error getting installation UUID: $e');
      return 'error_uuid_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Generate a random UUID for installation
  static String _generateRandomUUID() {
    // Generate a UUID-like string (32 characters, hexadecimal)
    final random = Random.secure();
    const chars = '0123456789abcdef';
    return List.generate(32, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Check if this is the first time using the app
  static Future<bool> isFirstTimeUsage() async {
    try {
      final uuid = await _secureStorage.read(key: 'installation_uuid');
      final isFirstTime = uuid == null || uuid.isEmpty;

      // If this is the first time, generate the installation UUID immediately
      if (isFirstTime) {
        if (AppConfig.showDebugInfo) {
          DebugLogger.device(
              '📱 [FIRST TIME] Generating installation UUID on first app launch');
        }
        await getInstallationUUID(); // This will generate and store the UUID
      }

      return isFirstTime;
    } catch (e) {
      DebugLogger.log('Error checking first time usage: $e');
      return true; // Assume first time if error
    }
  }

  // Check if first login attempt was already made
  static Future<bool> hasAttemptedFirstLogin() async {
    try {
      final hasAttempted =
          await _secureStorage.read(key: 'first_login_attempted');
      return hasAttempted == 'true';
    } catch (e) {
      DebugLogger.log('Error checking first login attempt: $e');
      return false; // Assume not attempted if error
    }
  }

  // Mark that first login attempt was made
  static Future<void> markFirstLoginAttempted() async {
    try {
      await _secureStorage.write(key: 'first_login_attempted', value: 'true');
      if (AppConfig.showDebugInfo) {
        DebugLogger.device(
            '📱 [FIRST LOGIN] Marked first login attempt as completed');
      }
    } catch (e) {
      DebugLogger.log('Error marking first login attempt: $e');
    }
  }

  // Mark that app has been initialized (opened for the first time)
  static Future<void> markAppInitialized() async {
    try {
      await _secureStorage.write(key: 'app_initialized', value: 'true');
      if (AppConfig.showDebugInfo) {
        DebugLogger.device('📱 [APP INIT] Marked app as initialized');
      }
    } catch (e) {
      DebugLogger.log('Error marking app as initialized: $e');
    }
  }

  // Check if app has been initialized
  static Future<bool> isAppInitialized() async {
    try {
      final initialized = await _secureStorage.read(key: 'app_initialized');
      return initialized == 'true';
    } catch (e) {
      DebugLogger.log('Error checking app initialization: $e');
      return false;
    }
  }

  // Get device identifier for API calls (installation UUID for production, mock for testing)
  static Future<String> getDeviceIdentifier() async {
    // TESTING MODE: Use static UUID for testing (uncomment line below)
    return 'b40a5047f6deac2dd337ec0292c44db2';

    // PRODUCTION MODE: Use real UUID generation (default behavior)

    // if (AppConfig.isProduction) {
    //   // Production: use installation UUID
    //   return await getInstallationUUID();
    // } else {
    //   // Testing: use mock UUID
    //   return 'b40a5047f6deac2dd337ec0292c44db2';
    // }
  }
}
