import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../config/app_config.dart';
import '../services/encryption_service.dart';
import '../services/jwt_service.dart';
import '../services/device_service.dart';
import '../models/login_response.dart';
import '../models/roles_response.dart';
import '../models/add_response.dart';
import '../models/locality.dart';
import '../models/role.dart';
import '../utils/debug_logger.dart';

class ApiService {
  static late Dio _dio;
  static final Map<String, dynamic> _storage = {};
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static void initialize() {
    // Initialize encryption service first
    EncryptionService.initialize();

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Accept all status codes so we can read response body even for errors
        // We'll check the 'err' field in the JSON response to determine success/error
        validateStatus: (status) {
          return status != null; // Accept all status codes
        },
      ),
    );

    // Add SSL certificate handling for development and release (mobile only)
    if (!kIsWeb) {
      try {
        (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
            DebugLogger.log(
              'SSL: Bypassing certificate for $host:$port',
              tag: 'SSL',
            );
            return true; // Accept all certificates in both debug and release
          };
          return client;
        };
      } catch (e) {
        DebugLogger.warning(
          'SSL: Could not configure SSL for web platform: $e',
        );
      }
    }

    // Add interceptors for proper error handling and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) {
          _logError(error);
          handler.next(error);
        },
      ),
    );

    _isInitialized = true;
  }

  static void _logRequest(RequestOptions options) {
    DebugLogger.api('REQUEST: ${options.method} ${options.uri}');
    DebugLogger.api('Headers: ${options.headers}');

    if (options.data != null) {
      String requestBody;
      if (options.data is String) {
        requestBody = options.data;
      } else if (options.data is FormData) {
        // Handle FormData for logging
        final formData = options.data as FormData;
        final fields = <String, String>{};
        for (final field in formData.fields) {
          fields[field.key] = field.value;
        }
        requestBody = json.encode(fields);
      } else {
        requestBody = json.encode(options.data);
      }

      DebugLogger.api('Body:');
      _printFormattedJson(requestBody);
    }
    DebugLogger.api('---');
  }

  static void _logResponse(Response response) {
    if (AppConfig.showDebugInfo) {
      DebugLogger.success('✅ API RESPONSE:');
      DebugLogger.log('   Status: ${response.statusCode}');
      DebugLogger.log('   Headers: ${response.headers}');

      String responseBody;
      if (response.data is String) {
        responseBody = response.data;
      } else {
        responseBody = json.encode(response.data);
      }

      DebugLogger.log('   Body:');
      _printFormattedJson(responseBody);
      DebugLogger.log('   ---');
    }
  }

  static void _printFormattedJson(String jsonString) {
    try {
      // Parse and re-encode with proper formatting
      final parsed = json.decode(jsonString);
      final formatted = const JsonEncoder.withIndent('   ').convert(parsed);
      DebugLogger.log(formatted);
    } catch (e) {
      // If parsing fails, print as is
      DebugLogger.log('   $jsonString');
    }
  }

  static void _logError(DioException error) {
    if (AppConfig.showDebugInfo) {
      DebugLogger.error('❌ API ERROR:');
      DebugLogger.error('   Type: ${error.type}');
      DebugLogger.error('   Message: ${error.message}');
      DebugLogger.error('   Status Code: ${error.response?.statusCode}');

      if (error.response?.data != null) {
        String errorBody;
        if (error.response!.data is String) {
          errorBody = error.response!.data;
        } else {
          errorBody = json.encode(error.response!.data);
        }
        DebugLogger.log('   Error Body:');
        _printFormattedJson(errorBody);
      }
      DebugLogger.log('   ---');
    }
  }

  static String _getSessionToken() {
    return _storage['session_token'] ?? '';
  }

  /// Check if the stored JWT token is expired
  static bool _isJWTExpired() {
    final expTimestamp = _storage['jwt_exp'];
    if (expTimestamp == null) return false; // No expiration info, assume valid

    final expirationTime = DateTime.fromMillisecondsSinceEpoch(
      expTimestamp * 1000,
    );
    final now = DateTime.now();

    return now.isAfter(expirationTime);
  }

  /// Get JWT token with expiration check
  static String _getJWTToken() {
    if (_isJWTExpired()) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.warning('🔐 [JWT] ⚠️ WARNING: JWT token is expired!');
        DebugLogger.api('🔐 [JWT] You may need to login again.');
      }
    }
    return _storage['jwt_token'] ?? '';
  }

  static Map<String, dynamic> getStorage() {
    return Map.from(_storage);
  }

  static Future<String> _getDeviceId() async {
    try {
      // Use the same device service as approl
      final deviceId = await DeviceService.getDeviceIdentifier();

      if (AppConfig.showDebugInfo) {
        DebugLogger.device('📱 [DEVICE] === DEVICE INFORMATION LOG ===');
        DebugLogger.device('📱 [DEVICE] Using device identifier: $deviceId');
        DebugLogger.device(
          '📱 [DEVICE] Identifier length: ${deviceId.length} characters',
        );
        DebugLogger.device(
          '📱 [DEVICE] Production mode: ${AppConfig.isProduction ? "PRODUCTION" : "DEVELOPMENT"}',
        );
      }

      return deviceId;
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.device('📱 [DEVICE] Error getting device UUID: $e');
        DebugLogger.device('📱 [DEVICE] Falling back to mock UUID');
      }

      // Fallback to mock UUID
      return 'da8a0b2aeba431afb40740415fe079b0';
    }
  }

  static String _generateSessionToken() {
    // Generate unique session with timestamp format: SYS{timestamp}
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return 'SYS$timestamp';
  }

  static void _storeSession(Map<String, dynamic> response) {
    _storage['session_token'] = response['session'];
    _storage['id_user'] = response['id_user'];
    _storage['jwt_token'] =
        response['token']; // Store JWT token for Bearer auth

    // Store expiration time if provided
    if (response['exp'] != null) {
      _storage['jwt_exp'] = response['exp'];
    }

    if (AppConfig.showDebugInfo) {
      DebugLogger.api('🔐 [SESSION] Stored session: ${response['session']}');
      DebugLogger.api('🔐 [USER] Stored user ID: ${response['id_user']}');
      DebugLogger.api(
        'JWT token stored: ${response['token']?.substring(0, 50)}...',
      );

      if (response['exp'] != null) {
        final expirationTime = DateTime.fromMillisecondsSinceEpoch(
          response['exp'] * 1000,
        );
        final now = DateTime.now();
        final timeUntilExpiry = expirationTime.difference(now);

        DebugLogger.api('Token expiration: ${expirationTime.toLocal()}');
        DebugLogger.api(
          'Time until expiry: ${timeUntilExpiry.inHours}h ${timeUntilExpiry.inMinutes % 60}m',
        );
        DebugLogger.api(
          'Token expires in: ${timeUntilExpiry.inDays} days, ${timeUntilExpiry.inHours % 24} hours',
        );
      }
    }
  }

  /// Login endpoint - /indexauth.php
  static Future<LoginResponse> login(String username, String password) async {
    // Hash password with MD5 for real API
    final hashedPassword = EncryptionService.hashPassword(password);
    final hashedName = encript5(
      username,
      '${AppConfig.passEncript5}${DateTime.now().day.toString().padLeft(2, '0')}',
    );

    final requestData = {
      'user': hashedName,
      'pass': hashedPassword,
      'emei': await _getDeviceId(),
      'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'session': _generateSessionToken(),
    };

    if (AppConfig.showDebugInfo) {
      DebugLogger.api('🔐 LOGIN REQUEST:');
      DebugLogger.log('📤 URL: ${AppConfig.baseUrl}/indexauth.php');
      DebugLogger.log(
        '📤 Session being sent to server: ${requestData['session']}',
      );
      _printFormattedJson(json.encode(requestData));
    }

    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));

      final mockResponse = LoginResponse(
        session: requestData['session'].toString(),
        err: 0,
        msgErr: 'Success',
        localit: [
          {'id_loc': 23, 'loc': 'Tinca'},
          {'id_loc': 24, 'loc': 'Toboliu'},
        ].map((loc) => Locality.fromJson(loc)).toList(),
      );

      if (AppConfig.showDebugInfo) {
        DebugLogger.log('🎭 MOCK LOGIN RESPONSE:');
        _printFormattedJson(json.encode(mockResponse.toJson()));
        DebugLogger.log('   ---');
      }

      _storeSession({
        'session': mockResponse.session,
        'id_user': '123',
        'token': JWTService.generateToken(
          userId: '123',
          username: username,
          additionalClaims: {
            'role': 'admin',
            'permissions': ['read', 'write', 'print'],
          },
        ),
      });
      return mockResponse;
    }

    try {
      final response = await _dio.post(
        '/idexauth.php',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'PostmanRuntime/7.32.3',
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      // Handle response data
      Map<String, dynamic> responseData;
      if (response.data is String) {
        try {
          responseData = json.decode(response.data);
        } catch (e) {
          responseData = {
            'err': 0,
            'session': requestData['session'],
            'localit': [
              {'id_loc': 23, 'loc': 'Tinca'},
              {'id_loc': 24, 'loc': 'Toboliu'},
            ],
          };
        }
      } else {
        responseData = response.data;
      }

      // Extract localities from server's JWT token
      final localities = _extractLocalitiesFromJWT(responseData['token']);

      final loginResponse = LoginResponse(
        session: responseData['session']?.toString() ?? '',
        err: responseData['err'] ?? 1,
        msgErr: responseData['msg_err'] ?? '',
        localit: localities,
      );

      // Store session for other endpoints
      _storeSession({
        'session': loginResponse.session,
        'id_user': responseData['id_user']?.toString() ?? '123',
        'token': responseData['token'] ?? '',
      });

      if (AppConfig.showDebugInfo) {
        DebugLogger.api(
          '🔐 [SESSION] Server returned session: ${loginResponse.session}',
        );
        _printFormattedJson(json.encode(loginResponse.toJson()));
      }

      return loginResponse;
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.error('❌ LOGIN ERROR: $e');
        if (e.toString().contains('SocketException') ||
            e.toString().contains('HandshakeException') ||
            e.toString().contains('Connection refused')) {
          DebugLogger.error(
            '🌐 NETWORK ERROR: Cannot connect to ${AppConfig.baseUrl}',
          );
        }
      }
      rethrow;
    }
  }

  /// Search roles endpoint - /indexroluri.php
  static Future<RolesResponse> searchRoles({
    required String idLoc,
    required String str,
    required String nrDom,
    required String rol,
  }) async {
    DebugLogger.api('🔐 [API] searchRoles method called');
    DebugLogger.api(
      '🔐 [API] Input parameters - idLoc: "$idLoc", str: "$str", nrDom: "$nrDom", rol: "$rol"',
    );

    // Send search parameters unencrypted (as per API specification)
    DebugLogger.api('🔐 [API] Using unencrypted parameters as per API spec');
    DebugLogger.api('🔐 [API] str: "$str"');
    DebugLogger.api('🔐 [API] nrDom: "$nrDom"');
    DebugLogger.api('🔐 [API] rol: "$rol"');

    final sessionToken = _getSessionToken();
    DebugLogger.api('🔐 [API] Using session token: $sessionToken');

    // Convert session to int if it's a string (like "SYS1761562751")
    int sessionValue;
    if (sessionToken.startsWith('SYS')) {
      // Extract the numeric part from "SYS1761562751"
      final numericPart = sessionToken.substring(3);
      sessionValue = int.tryParse(numericPart) ?? 0;
      DebugLogger.api('🔐 [API] Converted session to int: $sessionValue');
    } else {
      sessionValue = int.tryParse(sessionToken) ?? 0;
    }

    final requestData = {
      'id_loc':
          idLoc, // Keep as string (can be empty string or location ID as string)
      'str': str,
      'nr_dom': nrDom,
      'rol': rol,
      'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'session': sessionValue,
    };

    DebugLogger.api(
      'Request data created, session token: ${_getSessionToken()}',
    );

    if (AppConfig.showDebugInfo) {
      DebugLogger.api('🔐 [API] === SEARCH ROLES REQUEST ===');
      DebugLogger.api('🔐 [API] Endpoint: ${AppConfig.baseUrl}/idexroluri.php');
      DebugLogger.api('🔐 [API] Location ID: $idLoc');
      DebugLogger.api('🔐 [API] Street: $str');
      DebugLogger.api('🔐 [API] House number: $nrDom');
      DebugLogger.api('🔐 [API] Role: $rol');
      DebugLogger.api('🔐 [API] Session: ${requestData['session']}');
      DebugLogger.api('JWT Token: ${_getJWTToken().substring(0, 50)}...');
      DebugLogger.api('🔐 [API] Timestamp: ${requestData['time']}');
      DebugLogger.api('🔐 [API] Full Request Data:');
      _printFormattedJson(json.encode(requestData));
    }

    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));

      final mockResponse = RolesResponse(
        session: requestData['session'].toString(),
        err: 0,
        msgErr: 'Succes',
        countRoles: 1,
        date: [
          Role.fromJson({
            'id_rol': 1,
            'rol': 93,
            'pers': {
              'nume': 'Berescu',
              'pren': 'Alex',
              'cnp': 2312321321321,
              'tip_pers': 1,
            },
            'addr': {'loc': 'Oradea', 'str': 'Belsugului', 'nr_dom': '5'},
            'tax': [
              {
                'id_tip_taxa': 1,
                'id_tax2rol': 5,
                'id_tax2bord': 12,
                'nume_taxa': 'Apa',
                'unit_masura': 'mp3',
                'val_old': 1000,
                'data_citire_old': '0000-00-00',
                'tip_citire_old': 'C',
                'val_new_p': 56,
                'val_new_e': 70,
              },
            ],
          }),
        ],
      );

      if (AppConfig.showDebugInfo) {
        DebugLogger.api('=== SEARCH ROLES RESPONSE (MOCK) ===');
        DebugLogger.api('🔐 [API] Status: 200');
        _printFormattedJson(json.encode(mockResponse.toJson()));
      }

      return mockResponse;
    }

    try {
      if (AppConfig.showDebugInfo) {
        DebugLogger.api(
          '🔐 [API] Making HTTP request to: ${AppConfig.baseUrl}/idexroluri.php',
        );
        DebugLogger.api(
          'Request Headers: {Authorization: Bearer ${_getJWTToken().substring(0, 50)}...}',
        );
      }

      // Get JWT token and validate it's not empty
      final jwtToken = _getJWTToken();
      if (jwtToken.isEmpty) {
        throw Exception('JWT token is missing. Please login again.');
      }

      final response = await _dio.post(
        '/idexroluri.php',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'PostmanRuntime/7.32.3',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );

      Map<String, dynamic> responseData;
      if (response.data is String) {
        try {
          responseData = json.decode(response.data);
        } catch (e) {
          responseData = {
            'session': requestData['session'],
            'err': 1,
            'msg_err': 'Invalid response format',
            'count_roles': 0,
            'date': [],
          };
        }
      } else {
        responseData = response.data;
      }

      final rolesResponse = RolesResponse.fromJson(responseData);

      if (AppConfig.showDebugInfo) {
        DebugLogger.api('🔐 [API] === SEARCH ROLES RESPONSE ===');
        DebugLogger.api('🔐 [API] Status: ${response.statusCode}');
        DebugLogger.api('🔐 [API] Headers: ${response.headers}');
        DebugLogger.api('🔐 [API] Raw Response Body: ${response.data}');
        DebugLogger.api('🔐 [API] Parsed Response Data:');
        _printFormattedJson(json.encode(rolesResponse.toJson()));
        DebugLogger.log('   ---');
      }

      return rolesResponse;
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.error('❌ [API] Search roles error: $e');
      }
      rethrow;
    }
  }

  /// Add reading endpoint - /indexadauga.php
  static Future<AddResponse> addReading({
    required int idRol,
    required int idTipTaxa,
    required int idTax2rol,
    required int idTax2bord,
    required String valNew,
    required String dataCitireNew,
    required String tipCitireOld,
  }) async {
    // Send data unencrypted (as per API specification)
    DebugLogger.api(
      '🔐 [API] Using unencrypted data for addReading as per API spec',
    );
    DebugLogger.api('🔐 [API] val_new: $valNew');
    DebugLogger.api('🔐 [API] data_citire_new: $dataCitireNew');

    // Convert session to int if it's a string (like "SYS1761562751")
    final sessionToken = _getSessionToken();
    int sessionValue;
    if (sessionToken.startsWith('SYS')) {
      // Extract the numeric part from "SYS1761562751"
      final numericPart = sessionToken.substring(3);
      sessionValue = int.tryParse(numericPart) ?? 0;
    } else {
      sessionValue = int.tryParse(sessionToken) ?? 0;
    }

    final requestData = {
      'session': sessionValue,
      'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'id_rol': idRol,
      'id_tip_taxa': idTipTaxa,
      'id_tax2rol': idTax2rol,
      'id_tax2bord': idTax2bord,
      'val_new': valNew,
      'data_citire_new': dataCitireNew,
      'tip_citire_old': tipCitireOld,
    };

    if (AppConfig.showDebugInfo) {
      DebugLogger.api('🔐 [API] === ADD READING REQUEST ===');
      DebugLogger.api('🔐 [API] Endpoint: ${AppConfig.baseUrl}/idexadauga.php');
      DebugLogger.api('🔐 [API] Original session token: $sessionToken');
      DebugLogger.api('🔐 [API] Converted session to int: $sessionValue');
      DebugLogger.api('JWT Token: ${_getJWTToken().substring(0, 50)}...');
      DebugLogger.api('🔐 [API] Role ID: $idRol');
      DebugLogger.api('🔐 [API] Tax Type ID: $idTipTaxa');
      DebugLogger.api('🔐 [API] Tax2Role ID: $idTax2rol');
      DebugLogger.api('🔐 [API] Tax2Bord ID: $idTax2bord');
      DebugLogger.api('🔐 [API] New value: $valNew');
      DebugLogger.api('🔐 [API] Reading date: $dataCitireNew');
      DebugLogger.api('🔐 [API] Reading type: $tipCitireOld');
      DebugLogger.api('🔐 [API] Timestamp: ${requestData['time']}');
      DebugLogger.api('🔐 [API] Full Request Data:');
      _printFormattedJson(json.encode(requestData));
    }

    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));

      final mockResponse = AddResponse(
        session: requestData['session'].toString(),
        err: 0,
        msgErr: 'Succes',
      );

      if (AppConfig.showDebugInfo) {
        DebugLogger.api('=== ADD READING RESPONSE (MOCK) ===');
        DebugLogger.api('🔐 [API] Status: 200');
        _printFormattedJson(json.encode(mockResponse.toJson()));
      }

      return mockResponse;
    }

    try {
      final response = await _dio.post(
        '/idexadauga.php',
        data: requestData,
        options: Options(
          headers: {'Authorization': 'Bearer ${_getJWTToken()}'},
        ),
      );

      if (AppConfig.showDebugInfo) {
        DebugLogger.api('🔐 [API] === ADD READING RESPONSE ===');
        DebugLogger.api('🔐 [API] Status Code: ${response.statusCode}');
        DebugLogger.api(
            '🔐 [API] Response Data Type: ${response.data.runtimeType}');
      }

      Map<String, dynamic> responseData;
      if (response.data is String) {
        final responseString = response.data as String;
        if (responseString.isEmpty) {
          if (AppConfig.showDebugInfo) {
            DebugLogger.error('❌ [API] Response body is empty string');
          }
          responseData = {
            'session': requestData['session'],
            'err': 1,
            'msg_err': 'Eroare de server',
          };
        } else {
          try {
            responseData = json.decode(responseString);
            if (AppConfig.showDebugInfo) {
              DebugLogger.api('🔐 [API] Parsed JSON Response:');
              _printFormattedJson(responseString);
            }
          } catch (e) {
            if (AppConfig.showDebugInfo) {
              DebugLogger.error('❌ [API] Error parsing JSON: $e');
              DebugLogger.api('🔐 [API] Raw response: $responseString');
            }
            responseData = {
              'session': requestData['session'],
              'err': 1,
              'msg_err': 'Eroare de server',
            };
          }
        }
      } else if (response.data == null) {
        // Response data is null
        if (AppConfig.showDebugInfo) {
          DebugLogger.error('❌ [API] Response data is null');
        }
        responseData = {
          'session': requestData['session'],
          'err': 1,
          'msg_err': 'Eroare de server',
        };
      } else {
        try {
          responseData = response.data;
          if (AppConfig.showDebugInfo) {
            DebugLogger.api('🔐 [API] Response (non-string):');
            _printFormattedJson(json.encode(responseData));
          }
        } catch (e) {
          if (AppConfig.showDebugInfo) {
            DebugLogger.error('❌ [API] Error processing response: $e');
          }
          responseData = {
            'session': requestData['session'],
            'err': 1,
            'msg_err': 'Eroare de server',
          };
        }
      }

      final addResponse = AddResponse.fromJson(responseData);

      if (AppConfig.showDebugInfo) {
        DebugLogger.api('🔐 [API] === PARSED ADD READING RESPONSE ===');
        _printFormattedJson(json.encode(addResponse.toJson()));
      }

      return addResponse;
    } on DioException catch (e) {
      // Log the raw response body for debugging
      if (AppConfig.showDebugInfo) {
        DebugLogger.api('🔐 [API] === ADD READING ERROR RESPONSE ===');
        DebugLogger.api('🔐 [API] Status Code: ${e.response?.statusCode}');

        // Log raw response data
        if (e.response != null) {
          final responseData = e.response!.data;
          DebugLogger.api(
              '🔐 [API] Response Data Type: ${responseData.runtimeType}');

          if (responseData is String) {
            DebugLogger.api('🔐 [API] Raw Response Body (String):');
            if (responseData.isEmpty) {
              DebugLogger.api('   ⚠️ EMPTY STRING');
            } else {
              DebugLogger.api('   $responseData');
              // Try to format as JSON if possible
              try {
                json.decode(responseData);
                DebugLogger.api('🔐 [API] Parsed JSON Response:');
                _printFormattedJson(responseData);
              } catch (_) {
                // Not JSON, already logged as string
              }
            }
          } else if (responseData != null) {
            DebugLogger.api('🔐 [API] Raw Response Body:');
            try {
              _printFormattedJson(json.encode(responseData));
            } catch (jsonError) {
              DebugLogger.api('   $responseData');
            }
          } else {
            DebugLogger.api('   ⚠️ Response data is NULL');
          }
        } else {
          DebugLogger.api('   ⚠️ No response object in DioException');
        }
        DebugLogger.api('   ---');
      }

      // Try to extract msg_err from error response body
      if (e.response != null && e.response!.data != null) {
        try {
          Map<String, dynamic>? errorData;
          if (e.response!.data is String) {
            final responseString = e.response!.data as String;
            if (responseString.isEmpty) {
              if (AppConfig.showDebugInfo) {
                DebugLogger.error('❌ [API] Response body is empty string');
              }
            } else {
              errorData = json.decode(responseString) as Map<String, dynamic>;
            }
          } else {
            errorData = e.response!.data as Map<String, dynamic>?;
          }

          // If we have msg_err in the error response, return it
          if (errorData != null && errorData.containsKey('msg_err')) {
            final addResponse = AddResponse(
              session: requestData['session'].toString(),
              err: errorData['err'] ?? 1,
              msgErr: errorData['msg_err']?.toString() ?? 'Eroare necunoscută',
            );

            if (AppConfig.showDebugInfo) {
              DebugLogger.api('🔐 [API] === PARSED ERROR RESPONSE ===');
              _printFormattedJson(json.encode(addResponse.toJson()));
            }

            return addResponse;
          }
        } catch (parseError) {
          if (AppConfig.showDebugInfo) {
            DebugLogger.error(
                '❌ [API] Error parsing error response: $parseError');
          }
        }
      }

      if (AppConfig.showDebugInfo) {
        DebugLogger.error('❌ [API] Add reading error: $e');
      }
      rethrow;
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.error('❌ [API] Add reading error: $e');
      }
      rethrow;
    }
  }

  /// Clear stored session data
  static void clearSession() {
    _storage.clear();
    if (AppConfig.showDebugInfo) {
      DebugLogger.api('🔐 [SESSION] Cleared all session data');
    }
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    final token = _getJWTToken();
    final session = _getSessionToken();
    return token.isNotEmpty && session.isNotEmpty && !_isJWTExpired();
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _storage['id_user']?.toString();
  }

  /// Get current session token
  static String getCurrentSessionToken() {
    return _getSessionToken();
  }

  /// Get current JWT token
  static String getCurrentJWTToken() {
    return _getJWTToken();
  }

  static String encript5(String str, String pass) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final keyBytes = Uint8List.fromList(
      sha256.convert(utf8.encode(pass)).bytes,
    );
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(str, iv: iv);
    final ivAndEncrypted = iv.bytes + encrypted.bytes;
    String base64 = base64Encode(ivAndEncrypted);
    return base64
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '~');
  }

  static String? decript5(String str, String pass) {
    String base64 =
        str.replaceAll('-', '+').replaceAll('_', '/').replaceAll('~', '=');
    var data = base64Decode(base64);
    if (data.length < 16) return null;
    final iv = encrypt.IV(data.sublist(0, 16));
    final encrypted = data.sublist(16);
    final keyBytes = Uint8List.fromList(
      sha256.convert(utf8.encode(pass)).bytes,
    );
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    try {
      return encrypter.decrypt(encrypt.Encrypted(encrypted), iv: iv);
    } catch (e) {
      return null;
    }
  }

  /// Extract localities from server's JWT token
  static List<Locality> _extractLocalitiesFromJWT(String? token) {
    if (token == null || token.isEmpty) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.api('🔐 [LOCATIONS] No JWT token provided');
      }
      return [];
    }

    try {
      if (AppConfig.showDebugInfo) {
        DebugLogger.api(
          '🔐 [LOCATIONS] === EXTRACTING LOCALITIES FROM JWT ===',
        );
        DebugLogger.api('JWT Token: ${token.substring(0, 50)}...');
      }

      // Decode JWT payload (without verification)
      final parts = token.split('.');
      if (parts.length != 3) {
        if (AppConfig.showDebugInfo) {
          DebugLogger.api('🔐 [LOCATIONS] Invalid JWT format');
        }
        return [];
      }

      // Decode payload (second part)
      final payload = parts[1];
      // Add padding if needed
      final paddedPayload = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );

      final decodedBytes = base64Decode(paddedPayload);
      final payloadJson = json.decode(utf8.decode(decodedBytes));

      if (AppConfig.showDebugInfo) {
        DebugLogger.success('🔐 [LOCATIONS] JWT Payload decoded successfully');
        DebugLogger.api('Payload keys: ${payloadJson.keys.toList()}');
      }

      // Extract localities from payload
      final localitArray = payloadJson['localit'] as List<dynamic>?;
      if (localitArray == null) {
        if (AppConfig.showDebugInfo) {
          DebugLogger.api(
            '🔐 [LOCATIONS] No localit array found in JWT payload',
          );
        }
        return [];
      }

      if (AppConfig.showDebugInfo) {
        DebugLogger.api(
          '🔐 [LOCATIONS] Found ${localitArray.length} localities in JWT',
        );
      }

      final localities = localitArray
          .map((locJson) => Locality.fromJson(locJson as Map<String, dynamic>))
          .toList();

      if (AppConfig.showDebugInfo) {
        DebugLogger.api('🔐 [LOCATIONS] Extracted localities:');
        for (final locality in localities) {
          DebugLogger.api('  - ${locality.loc} (ID: ${locality.idLoc})');
        }
      }

      return localities;
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.api(
          '🔐 [LOCATIONS] Error extracting localities from JWT: $e',
        );
      }
      return [];
    }
  }
}
