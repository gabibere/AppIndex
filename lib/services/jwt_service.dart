import 'dart:convert';
import 'package:crypto/crypto.dart';

class JWTService {
  static const String _secretKey = 'AppIndexJWTSecret2024!@#';
  static const String _issuer = 'appindex';
  static const Duration _tokenExpiry = Duration(hours: 24);

  /// Generate a JWT token
  static String generateToken({
    required String userId,
    required String username,
    Map<String, dynamic>? additionalClaims,
  }) {
    final now = DateTime.now();
    final expiry = now.add(_tokenExpiry);

    final payload = {
      'iss': _issuer, // Issuer
      'sub': userId, // Subject (user ID)
      'aud': 'appindex_app', // Audience
      'iat': now.millisecondsSinceEpoch ~/ 1000, // Issued at
      'exp': expiry.millisecondsSinceEpoch ~/ 1000, // Expires at
      'nbf': now.millisecondsSinceEpoch ~/ 1000, // Not before
      'usr': username, // Username
      'sid': _generateSessionId(), // Session ID
      ...?additionalClaims, // Additional claims
    };

    // For development, we'll create a simple JWT-like token
    // In production, you would use a proper JWT library
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final headerEncoded = _base64UrlEncode(json.encode(header));
    final payloadEncoded = _base64UrlEncode(json.encode(payload));
    final signature = _generateSignature('$headerEncoded.$payloadEncoded');

    return '$headerEncoded.$payloadEncoded.$signature';
  }

  /// Validate a JWT token
  static Map<String, dynamic>? validateToken(String token) {
    try {
      final payload = decodePayload(token);
      if (payload == null) return null;

      // Check if token is expired
      if (payload['exp'] != null) {
        final expiry =
            DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        if (DateTime.now().isAfter(expiry)) {
          return null;
        }
      }

      // Check issuer
      if (payload['iss'] != _issuer) {
        return null;
      }

      return payload;
    } catch (e) {
      return null;
    }
  }

  /// Check if token is expired
  static bool isTokenExpired(String token) {
    try {
      final payload = decodePayload(token);
      if (payload == null) return true;

      if (payload['exp'] != null) {
        final expiry =
            DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        return DateTime.now().isAfter(expiry);
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Get token expiration date
  static DateTime? getTokenExpirationDate(String token) {
    try {
      final payload = decodePayload(token);
      if (payload != null && payload['exp'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get time until token expires
  static Duration? getTimeUntilExpiry(String token) {
    try {
      final expiry = getTokenExpirationDate(token);
      if (expiry != null) {
        return expiry.difference(DateTime.now());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Decode JWT payload without verification (for data extraction only)
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      String payload = parts[1];

      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      // Replace URL-safe characters
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      // Decode base64
      final bytes = base64Decode(payload);
      final jsonString = utf8.decode(bytes);

      // Parse JSON
      return json.decode(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Extract user ID from token
  static String? getUserId(String token) {
    try {
      final payload = decodePayload(token);
      return payload?['sub']?.toString();
    } catch (e) {
      return null;
    }
  }

  /// Extract username from token
  static String? getUsername(String token) {
    try {
      final payload = decodePayload(token);
      return payload?['usr']?.toString();
    } catch (e) {
      return null;
    }
  }

  /// Extract session ID from token
  static String? getSessionId(String token) {
    try {
      final payload = decodePayload(token);
      return payload?['sid']?.toString();
    } catch (e) {
      return null;
    }
  }

  /// Check if token needs refresh (expires within 1 hour)
  static bool needsRefresh(String token) {
    try {
      final timeUntilExpiry = getTimeUntilExpiry(token);
      if (timeUntilExpiry != null) {
        return timeUntilExpiry.inHours < 1;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Generate a unique session ID
  static String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000) % 1000000;
    return 'SYS$timestamp$random';
  }

  /// Base64 URL encode
  static String _base64UrlEncode(String data) {
    final bytes = utf8.encode(data);
    final base64 = base64Encode(bytes);
    return base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  /// Generate signature (simplified for development)
  static String _generateSignature(String data) {
    // In production, use proper HMAC-SHA256
    final bytes = utf8.encode('$_secretKey$data');
    final hash = sha256.convert(bytes);
    return _base64UrlEncode(hash.toString());
  }
}
