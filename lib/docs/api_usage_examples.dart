// API Usage Examples for AppIndex
// This file demonstrates how to use the new API endpoints

import '../services/api_service.dart';
import '../utils/debug_logger.dart';

class ApiUsageExamples {
  /// Example: Login and get locations
  static Future<void> loginExample() async {
    try {
      DebugLogger.search('🔍 Logging in...');
      final response = await ApiService.login('username', 'password');

      if (response.isSuccess) {
        DebugLogger.success('✅ Login successful!');
        DebugLogger.location('Found ${response.localit.length} locations:');
        for (var location in response.localit) {
          DebugLogger.location('  - ${location.loc} (ID: ${location.idLoc})');
        }
      } else {
        DebugLogger.log('❌ Error: ${response.msgErr}');
      }
    } catch (e) {
      DebugLogger.log('❌ Error logging in: $e');
    }
  }

  /// Example: Search for roles by address
  static Future<void> searchRolesExample() async {
    try {
      DebugLogger.search('🔍 Searching for roles...');
      final response = await ApiService.searchRoles(
        idLoc: '23', // Tinca
        str: 'Belsugului',
        nrDom: '5',
        rol: '93',
      );

      if (response.isSuccess) {
        DebugLogger.success('✅ Found ${response.countRoles} roles');

        for (var role in response.date) {
          DebugLogger.log('  Role ${role.rol}:');
          DebugLogger.log('    Person: ${role.pers.fullName}');
          DebugLogger.log('    Address: ${role.addr.fullAddress}');
          DebugLogger.log('    Taxes: ${role.tax.length} items');
        }
      } else {
        DebugLogger.log('❌ Error: ${response.msgErr}');
      }
    } catch (e) {
      DebugLogger.search('❌ Error searching roles: $e');
    }
  }

  /// Example: Add meter reading
  static Future<void> addReadingExample() async {
    try {
      DebugLogger.search('🔍 Adding meter reading...');
      final response = await ApiService.addReading(
        idRol: 1,
        idTipTaxa: 1,
        idTax2rol: 5,
        idTax2bord: 12,
        valNew: '1200',
        dataCitireNew: '2024-01-15',
        tipCitireOld: 'C',
      );

      if (response.isSuccess) {
        DebugLogger.success('✅ Reading added successfully: ${response.msgErr}');
      } else {
        DebugLogger.log('❌ Error: ${response.msgErr}');
      }
    } catch (e) {
      DebugLogger.log('❌ Error adding reading: $e');
    }
  }

  /// Example: Complete workflow
  static Future<void> completeWorkflowExample() async {
    DebugLogger.log('🚀 Starting complete workflow example...');

    // Step 1: Login and get locations
    await loginExample();

    // Step 2: Search for roles
    await searchRolesExample();

    // Step 3: Add reading
    await addReadingExample();

    DebugLogger.success('✅ Complete workflow finished!');
  }
}

// Usage in your app:
// 
// // In a widget or service:
// await ApiUsageExamples.loginExample();
// await ApiUsageExamples.searchRolesExample();
// await ApiUsageExamples.addReadingExample();
// 
// // Or run complete workflow:
// await ApiUsageExamples.completeWorkflowExample();
