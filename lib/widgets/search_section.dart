import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/search_provider.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../services/localization_service.dart';
import 'scaffold_message.dart';
import 'location_dropdown.dart';
import '../utils/debug_logger.dart';

class SearchSection extends StatefulWidget {
  final VoidCallback? onSearchTriggered;

  const SearchSection({super.key, this.onSearchTriggered});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _rolController = TextEditingController();
  String? _selectedLocationId;
  String? _selectedLocationName;

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _rolController.dispose();
    super.dispose();
  }

  void _performSearch() {
    // Hide keyboard before search
    FocusScope.of(context).unfocus();

    final locationId = _selectedLocationId ?? '';
    final street = _streetController.text.trim();
    final houseNumber = _houseNumberController.text.trim();
    final rol = _rolController.text.trim();

    DebugLogger.search('🔍 [SEARCH] Button tapped!');
    DebugLogger.search('🔍 [SEARCH] Location ID: "$locationId"');
    DebugLogger.search('🔍 [SEARCH] Street: "$street"');
    DebugLogger.search('🔍 [SEARCH] House Number: "$houseNumber"');
    DebugLogger.search('🔍 [SEARCH] Role: "$rol"');

    // Allow search with any fields filled (remove strict validation)
    if (locationId.isNotEmpty ||
        street.isNotEmpty ||
        houseNumber.isNotEmpty ||
        rol.isNotEmpty) {
      DebugLogger.search('🔍 [SEARCH] Fields filled, calling search...');
      final searchProvider = Provider.of<SearchProvider>(
        context,
        listen: false,
      );
      searchProvider.search(
        idLoc: locationId,
        str: street,
        nrDom: houseNumber,
        rol: rol,
      );

      // Trigger scroll to results after a short delay to allow search to start
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onSearchTriggered?.call();
      });
    } else {
      DebugLogger.search(
        '🔍 [SEARCH] No fields filled - please enter at least one search criteria',
      );
    }
  }

  void _clearSearch() {
    setState(() {
      _selectedLocationId = null;
      _selectedLocationName = null;
    });
    _streetController.clear();
    _houseNumberController.clear();
    _rolController.clear();
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.clearSearch();
  }

  void _clearFieldAndSearch(String fieldType) {
    setState(() {
      // Clear the specific field
      switch (fieldType) {
        case 'street':
          _streetController.clear();
          break;
        case 'houseNumber':
          _houseNumberController.clear();
          break;
        case 'rol':
          _rolController.clear();
          break;
        case 'location':
          _selectedLocationId = null;
          _selectedLocationName = null;
          break;
      }
    });

    // Clear search results and data
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.clearSearch();

    // Auto-search with remaining filters if other fields are filled
    final locationId = _selectedLocationId ?? '';
    final street = _streetController.text.trim();
    final houseNumber = _houseNumberController.text.trim();
    final rol = _rolController.text.trim();

    // Check if any other fields are still filled
    if (locationId.isNotEmpty ||
        street.isNotEmpty ||
        houseNumber.isNotEmpty ||
        rol.isNotEmpty) {
      DebugLogger.search('🔍 [CLEAR] Auto-searching with remaining filters');
      searchProvider.search(
        idLoc: locationId,
        str: street,
        nrDom: houseNumber,
        rol: rol,
      );

      // Note: No scroll trigger here - only when search button is pressed
    } else {
      DebugLogger.search('🔍 [CLEAR] All fields cleared - no auto-search');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with title and location button
            _buildSectionHeader(),

            const SizedBox(height: 16),

            // Search card
            Card(
              elevation: 4,
              shadowColor: const Color(
                AppConfig.primaryColor,
              ).withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Search form
                    _buildSearchForm(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchForm() {
    return Column(
      children: [
        // Location dropdown
        LocationDropdown(
          selectedLocationId: _selectedLocationId,
          selectedLocationName: _selectedLocationName,
          onLocationChanged: (locationId, locationName) {
            setState(() {
              _selectedLocationId = locationId;
              _selectedLocationName = locationName;
            });

            // If location was cleared, trigger clear and search logic
            if (locationId == null) {
              _clearFieldAndSearch('location');
            }
          },
        ),

        const SizedBox(height: 16),

        // Street field
        TextField(
          controller: _streetController,
          decoration: InputDecoration(
            labelText: LocalizationService.getString('search.street'),
            hintText: LocalizationService.getString('search.street_hint'),
            prefixIcon: const Icon(Icons.streetview),
            suffixIcon: _streetController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _clearFieldAndSearch('street');
                    },
                    tooltip: LocalizationService.getString(
                      'search.street_clear',
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            filled: true,
            fillColor: const Color(AppConfig.backgroundColor),
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // House number field
        TextField(
          controller: _houseNumberController,
          decoration: InputDecoration(
            labelText: LocalizationService.getString('search.house_number'),
            hintText: LocalizationService.getString('search.house_number_hint'),
            prefixIcon: const Icon(Icons.home),
            suffixIcon: _houseNumberController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _clearFieldAndSearch('houseNumber');
                    },
                    tooltip: LocalizationService.getString(
                        'search.house_number_clear'),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            filled: true,
            fillColor: const Color(AppConfig.backgroundColor),
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // Rol field
        TextField(
          controller: _rolController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: LocalizationService.getString('search.rol'),
            hintText: LocalizationService.getString('search.rol_hint'),
            prefixIcon: const Icon(Icons.numbers),
            suffixIcon: _rolController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _clearFieldAndSearch('rol');
                    },
                    tooltip: LocalizationService.getString('search.rol_clear'),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            filled: true,
            fillColor: const Color(AppConfig.backgroundColor),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _performSearch(),
          onChanged: (value) => setState(() {}),
        ),

        const SizedBox(height: 24),

        // Search button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConfig.primaryColor),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(
                AppConfig.primaryColor,
              ).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.getString('search.search'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Clear button
        TextButton(
          onPressed: _clearSearch,
          child: Text(
            LocalizationService.getString('search.clear_all'),
            style: const TextStyle(
              color: Color(AppConfig.primaryColor),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        // Section title
        Expanded(
          child: Text(
            LocalizationService.getString('search.title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConfig.textColor),
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // Get current location
    bool success = await locationProvider.getCurrentLocation();

    if (success && locationProvider.currentAddress != null) {
      // Parse the address to extract city and street
      final addressParts = _parseAddress(locationProvider.currentAddress!);

      // Auto-fill the location, street, and house number fields
      DebugLogger.location('🌍 [LOCATION] Parsed address parts:');
      DebugLogger.location('🌍 [LOCATION] City: "${addressParts['city']}"');
      DebugLogger.location('🌍 [LOCATION] Street: "${addressParts['street']}"');
      DebugLogger.location(
        '🌍 [LOCATION] House Number: "${addressParts['houseNumber']}"',
      );

      setState(() {
        if (addressParts['city']?.isNotEmpty == true) {
          // For now, we'll just set the location name
          // In a real implementation, you'd need to find the matching location ID
          _selectedLocationName = addressParts['city']!;
        }
        if (addressParts['street']?.isNotEmpty == true) {
          _streetController.text = addressParts['street']!;
        }
        if (addressParts['houseNumber']?.isNotEmpty == true) {
          _houseNumberController.text = addressParts['houseNumber']!;
          DebugLogger.success(
            '🌍 [LOCATION] ✅ Auto-filled house number: "${addressParts['houseNumber']}"',
          );
        } else {
          DebugLogger.warning(
            '🌍 [LOCATION] ⚠️ No house number found in address',
          );
        }
      });

      // Show success message with full address
      context.showSuccessMessage(
        message: LocalizationService.getString('location.location_updated'),
        additionalInfo: locationProvider.currentAddress!,
        duration: const Duration(seconds: 4),
      );
    } else {
      // Show enhanced error handling with permission dialog
      String error = locationProvider.error ??
          LocalizationService.getString('location.location_error');
      if (error.contains('Location services are disabled')) {
        _showLocationServicesDialog();
      } else if (error.contains('permission') || error.contains('Permission')) {
        _showPermissionDialog();
      } else {
        context.showErrorMessage(
          message: LocalizationService.getString('location.location_error'),
          additionalInfo: error,
          duration: const Duration(seconds: 5),
          actionLabel: LocalizationService.getString('location.try_again'),
          onAction: () {
            _getCurrentLocation();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        );
      }
    }
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocalizationService.getString('location.services_disabled'),
        ),
        content: Text(
          LocalizationService.getString('location.services_disabled_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService.getString('auth.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open location settings
            },
            child: Text(
              LocalizationService.getString('location.open_settings'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(
                  AppConfig.warningColor,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_disabled,
                color: const Color(AppConfig.warningColor),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocalizationService.getString('location.permission_required'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.textColor),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocalizationService.getString('location.permission_message'),
              style: const TextStyle(
                fontSize: 16,
                color: Color(AppConfig.textColor),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(
                  AppConfig.primaryColor,
                ).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(
                    AppConfig.primaryColor,
                  ).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(AppConfig.primaryColor),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LocalizationService.getString('location.permission_info'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(AppConfig.textSecondaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              LocalizationService.getString('auth.cancel'),
              style: const TextStyle(
                color: Color(AppConfig.textSecondaryColor),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),

          // Action buttons row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Open Settings button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  LocationService.openAppSettings();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: const Color(AppConfig.primaryColor),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  LocalizationService.getString('location.settings'),
                  style: const TextStyle(
                    color: Color(AppConfig.primaryColor),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Grant Permission button
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Try to request permission directly
                  final locationProvider = Provider.of<LocationProvider>(
                    context,
                    listen: false,
                  );
                  await locationProvider.requestPermission();
                  // Retry getting location
                  _getCurrentLocation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  LocalizationService.getString('location.grant_permission'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Parse address to extract city, street, and house number
  Map<String, String> _parseAddress(String address) {
    DebugLogger.location('🌍 [PARSING] Processing address: "$address"');
    final parts = address.split(',');

    String street = '';
    String city = '';
    String houseNumber = '';

    if (parts.length >= 2) {
      String streetWithNumber = parts[0].trim();

      // Extract house number from street with number
      // Improved regex to handle various formats: "5", "5A", "10B", "123", "123A"
      // Also handles cases like "Strada Mihai Viteazu 5A" or "Bulevardul 1 Decembrie 1918 10B"
      final houseNumberMatch = RegExp(
        r'\s+(\d+[A-Za-z]?)\s*$',
      ).firstMatch(streetWithNumber);

      if (houseNumberMatch != null) {
        houseNumber = houseNumberMatch.group(1) ?? '';
        DebugLogger.location(
          '🌍 [PARSING] Found house number: "$houseNumber" in "$streetWithNumber"',
        );
      } else {
        // Try alternative pattern for cases like "nr. 5A" or "No. 10B"
        final altMatch = RegExp(
          r'(?:nr\.?|no\.?|number)\s*(\d+[A-Za-z]?)\s*$',
          caseSensitive: false,
        ).firstMatch(streetWithNumber);
        if (altMatch != null) {
          houseNumber = altMatch.group(1) ?? '';
          DebugLogger.location(
            'Found house number (alt): "$houseNumber" in "$streetWithNumber"',
          );
        } else {
          DebugLogger.location(
            '🌍 [PARSING] No house number found in "$streetWithNumber"',
          );
        }
      }

      if (_isRomanianNumberedStreet(streetWithNumber)) {
        street = _cleanRomanianStreet(streetWithNumber);
      } else {
        street = streetWithNumber
            .replaceAll(RegExp(r'\s+\d+[A-Za-z]?\s*$'), '')
            .trim();
      }

      city = parts[1].trim();
    } else if (parts.length == 1) {
      final singlePart = parts[0].trim();
      if (singlePart.contains(RegExp(r'\d+'))) {
        // Extract house number
        final houseNumberMatch = RegExp(
          r'\s+(\d+[A-Za-z]?)\s*$',
        ).firstMatch(singlePart);
        if (houseNumberMatch != null) {
          houseNumber = houseNumberMatch.group(1) ?? '';
          DebugLogger.location(
            '🌍 [PARSING] Found house number: "$houseNumber" in "$singlePart"',
          );
        } else {
          // Try alternative pattern for cases like "nr. 5A" or "No. 10B"
          final altMatch = RegExp(
            r'(?:nr\.?|no\.?|number)\s*(\d+[A-Za-z]?)\s*$',
            caseSensitive: false,
          ).firstMatch(singlePart);
          if (altMatch != null) {
            houseNumber = altMatch.group(1) ?? '';
            DebugLogger.location(
              'Found house number (alt): "$houseNumber" in "$singlePart"',
            );
          } else {
            DebugLogger.location(
              '🌍 [PARSING] No house number found in "$singlePart"',
            );
          }
        }

        if (_isRomanianNumberedStreet(singlePart)) {
          street = _cleanRomanianStreet(singlePart);
        } else {
          street =
              singlePart.replaceAll(RegExp(r'\s+\d+[A-Za-z]?\s*$'), '').trim();
        }
      } else {
        city = singlePart;
      }
    }

    DebugLogger.location('🌍 [PARSING] Final parsed result:');
    DebugLogger.location('🌍 [PARSING] Street: "$street"');
    DebugLogger.location('🌍 [PARSING] City: "$city"');
    DebugLogger.location('🌍 [PARSING] House Number: "$houseNumber"');

    return {'street': street, 'city': city, 'houseNumber': houseNumber};
  }

  bool _isRomanianNumberedStreet(String street) {
    final patterns = [
      RegExp(r'^Strada\s+\d+', caseSensitive: false),
      RegExp(r'^Calea\s+\d+', caseSensitive: false),
      RegExp(r'^Bulevardul\s+\d+', caseSensitive: false),
      RegExp(r'^Aleea\s+\d+', caseSensitive: false),
    ];

    return patterns.any((pattern) => pattern.hasMatch(street));
  }

  String _cleanRomanianStreet(String street) {
    return street.replaceAll(RegExp(r'\s+\d+\s*$'), '').trim();
  }
}
