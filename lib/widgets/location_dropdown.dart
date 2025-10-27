import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/debug_logger.dart';

class LocationDropdown extends StatefulWidget {
  final String? selectedLocationId;
  final String? selectedLocationName;
  final Function(String? locationId, String? locationName) onLocationChanged;
  final bool enabled;

  const LocationDropdown({
    super.key,
    this.selectedLocationId,
    this.selectedLocationName,
    required this.onLocationChanged,
    this.enabled = true,
  });

  @override
  State<LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends State<LocationDropdown> {
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedLocationId;
  String? _selectedLocationName;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = widget.selectedLocationId;
    _selectedLocationName = widget.selectedLocationName;
    _loadLocations();
  }

  @override
  void didUpdateWidget(LocationDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocationId != widget.selectedLocationId) {
      _selectedLocationId = widget.selectedLocationId;
      _selectedLocationName = widget.selectedLocationName;
    }
  }

  Future<void> _loadLocations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get locations from JWT token payload instead of separate API call
      final jwtToken = ApiService.getCurrentJWTToken();
      if (jwtToken.isNotEmpty) {
        // Decode JWT token to get distinct localities
        final locations = _extractDistinctLocalitiesFromJWT(jwtToken);

        if (mounted) {
          setState(() {
            _locations = locations;
            _isLoading = false;
          });

          // Auto-select first location if none selected - defer to after build
          if (_selectedLocationId == null && locations.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedLocationId = locations.first['id_loc'].toString();
                  _selectedLocationName = locations.first['loc'] as String;
                });

                if (AppConfig.showDebugInfo) {
                  DebugLogger.location(
                      'Auto-selecting first location: $_selectedLocationName (ID: $_selectedLocationId)');
                }

                // Notify parent widget about the selection
                widget.onLocationChanged(
                    _selectedLocationId, _selectedLocationName);
              }
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No authentication token found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading locations: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _extractDistinctLocalitiesFromJWT(
      String jwtToken) {
    try {
      if (AppConfig.showDebugInfo) {
        DebugLogger.api(
            '🔐 [LOCATIONS] === EXTRACTING DISTINCT LOCALITIES FROM JWT ===');
        DebugLogger.api('JWT Token: ${jwtToken.substring(0, 50)}...');
      }

      // Decode JWT token to get payload
      final parts = jwtToken.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid JWT token format');
      }

      // Decode payload (base64url)
      final payload = parts[1];
      // Add padding if needed
      final paddedPayload =
          payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
      final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
      final payloadJson = json.decode(decodedPayload);

      if (AppConfig.showDebugInfo) {
        DebugLogger.success('🔐 [LOCATIONS] JWT Payload decoded successfully');
        DebugLogger.api(
            '🔐 [LOCATIONS] Found localit array: ${payloadJson['localit'] != null}');
      }

      // Extract localit array from payload
      if (payloadJson['localit'] != null) {
        final localitArray =
            List<Map<String, dynamic>>.from(payloadJson['localit']);

        if (AppConfig.showDebugInfo) {
          DebugLogger.api(
              '🔐 [LOCATIONS] Raw localit array length: ${localitArray.length}');
        }

        // Keep only distinct localities (remove duplicates by id_loc)
        final distinctLocations = <int, Map<String, dynamic>>{};
        for (final location in localitArray) {
          final idLoc = location['id_loc'] as int;
          if (!distinctLocations.containsKey(idLoc)) {
            distinctLocations[idLoc] = location;
          }
        }

        final uniqueList = distinctLocations.values.toList();

        if (AppConfig.showDebugInfo) {
          DebugLogger.api(
              '🔐 [LOCATIONS] Distinct localities found: ${uniqueList.length}');
          DebugLogger.api(
              '🔐 [LOCATIONS] Note: Server returns duplicates, we keep only distinct localities');
          for (final location in uniqueList) {
            DebugLogger.api(
                '   - ${location['loc']} (ID: ${location['id_loc']})');
          }
        }

        return uniqueList;
      }

      return [];
    } catch (e) {
      DebugLogger.location(
          '❌ [LOCATIONS] Error extracting locations from JWT: $e');
      return [];
    }
  }

  void _onLocationChanged(String? locationId, String? locationName) {
    setState(() {
      _selectedLocationId = locationId;
      _selectedLocationName = locationName;
    });
    widget.onLocationChanged(locationId, locationName);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          LocalizationService.getString('search.city'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(AppConfig.textColor),
              ),
        ),
        const SizedBox(height: 8),

        // Dropdown Container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            border: Border.all(
              color: _errorMessage != null
                  ? const Color(AppConfig.errorColor)
                  : const Color(AppConfig.secondaryColor),
            ),
            color: const Color(AppConfig.backgroundColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              onTap: widget.enabled && !_isLoading ? _showLocationPicker : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    // Location icon
                    Icon(
                      Icons.location_city,
                      color: _selectedLocationId != null
                          ? const Color(AppConfig.primaryColor)
                          : const Color(AppConfig.textSecondaryColor),
                      size: 20,
                    ),
                    const SizedBox(width: 12),

                    // Selected location or placeholder
                    Expanded(
                      child: _buildLocationText(),
                    ),

                    // Loading or dropdown arrow
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(AppConfig.primaryColor),
                          ),
                        ),
                      )
                    else if (_errorMessage != null)
                      Icon(
                        Icons.error_outline,
                        color: const Color(AppConfig.errorColor),
                        size: 20,
                      )
                    else
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: const Color(AppConfig.textSecondaryColor),
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: const Color(AppConfig.errorColor),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(AppConfig.errorColor),
                      ),
                ),
              ),
              // Retry button
              TextButton(
                onPressed: _loadLocations,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: const Color(AppConfig.primaryColor),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLocationText() {
    if (_selectedLocationName != null && _selectedLocationName!.isNotEmpty) {
      return Text(
        _selectedLocationName!,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(AppConfig.textColor),
              fontWeight: FontWeight.w500,
            ),
      );
    } else {
      return Text(
        LocalizationService.getString('search.city_hint'),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(AppConfig.textSecondaryColor),
            ),
      );
    }
  }

  void _showLocationPicker() {
    if (_locations.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationPicker(),
    );
  }

  Widget _buildLocationPicker() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(AppConfig.surfaceColor),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(AppConfig.textSecondaryColor),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.location_city,
                  color: const Color(AppConfig.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    LocalizationService.getString('search.select_city'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(AppConfig.textColor),
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(AppConfig.backgroundColor),
                    foregroundColor: const Color(AppConfig.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: LocalizationService.getString('search.search_city'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                ),
                filled: true,
                fillColor: const Color(AppConfig.backgroundColor),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),

          const SizedBox(height: 16),

          // Locations list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final location = _locations[index];
                final locationId = location['id_loc'].toString();
                final locationName = location['loc'] as String;
                final isSelected = _selectedLocationId == locationId;

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    color: isSelected
                        ? const Color(AppConfig.primaryColor)
                            .withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.location_city,
                      color: isSelected
                          ? const Color(AppConfig.primaryColor)
                          : const Color(AppConfig.textSecondaryColor),
                    ),
                    title: Text(
                      locationName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? const Color(AppConfig.primaryColor)
                                : const Color(AppConfig.textColor),
                          ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: const Color(AppConfig.primaryColor),
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      _onLocationChanged(locationId, locationName);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
