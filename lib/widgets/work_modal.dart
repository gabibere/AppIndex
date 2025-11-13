import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/role.dart';
import '../models/tax.dart';
import '../services/localization_service.dart';
import '../services/api_service.dart';
import '../services/error_handling_service.dart';
import '../providers/reading_date_provider.dart';
import '../utils/debug_logger.dart';

class WorkModal extends StatefulWidget {
  final Role? role;
  final VoidCallback? onDataUpdated;

  const WorkModal({super.key, this.role, this.onDataUpdated});

  @override
  State<WorkModal> createState() => _WorkModalState();
}

class _WorkModalState extends State<WorkModal> {
  // Tax reading controllers
  final Map<String, TextEditingController> _readingControllers = {};
  final Map<String, DateTime> _readingDates = {};
  final Map<String, String> _readingTypes = {};
  final Map<String, String> _lastReadings = {};
  final Map<String, String> _lastDates = {};
  final Map<String, String> _lastTypes = {};

  // Overlay entries for messages above modal
  OverlayEntry? _successOverlay;
  OverlayEntry? _errorOverlay;

  // Validation state
  final Map<String, bool> _fieldErrors = {};

  // Saved data state
  final Map<String, bool> _isSaved = {};
  final Map<String, String> _savedValues = {};
  final Map<String, String> _savedDates = {};
  final Map<String, String> _savedTypes = {};

  // Loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeTaxData();
  }

  void _initializeTaxData() {
    // Get global reading date from provider
    final readingDateProvider = Provider.of<ReadingDateProvider>(
      context,
      listen: false,
    );
    final globalReadingDate = readingDateProvider.selectedDate;

    // Initialize with actual tax data from the role
    if (widget.role != null && widget.role!.tax.isNotEmpty) {
      for (final tax in widget.role!.tax) {
        final taxType = _getTaxTypeFromName(tax.numeTaxa);

        _readingControllers[taxType] = TextEditingController();
        _readingDates[taxType] = globalReadingDate; // Use global reading date
        _readingTypes[taxType] = _getUIReadingType(tax.tipCitireOld);

        // Use real data from API response
        _lastReadings[taxType] = tax.valOld.toString();
        _lastDates[taxType] = _formatDate(tax.dataCitireOld);
        _lastTypes[taxType] = _getReadingTypeTranslation(tax.tipCitireOld);

        // Set initial value based on reading type
        _updateValueForReadingType(taxType);
      }
    } else {
      // Fallback to mock data if no role data
      final taxTypes = [
        'electricity',
        'gas',
        'water',
        'impozit',
        'heating',
        'internet',
      ];

      for (final taxType in taxTypes) {
        _readingControllers[taxType] = TextEditingController();
        _readingDates[taxType] = globalReadingDate; // Use global reading date
        _readingTypes[taxType] = 'Citire (C)';

        // Mock last reading data
        _lastReadings[taxType] = _getMockLastReading(taxType);
        _lastDates[taxType] = _getMockLastDate(taxType);
        _lastTypes[taxType] = 'Manuală';

        // Set initial value based on reading type
        _updateValueForReadingType(taxType);
      }
    }
  }

  String _getMockLastReading(String taxType) {
    switch (taxType) {
      case 'electricity':
        return '12345';
      case 'gas':
        return '6789';
      case 'water':
        return '2345';
      case 'impozit':
        return '1500';
      case 'heating':
        return '890';
      case 'internet':
        return '45';
      default:
        return '0';
    }
  }

  String _getMockLastDate(String taxType) {
    final daysAgo = {
      'electricity': 15,
      'gas': 20,
      'water': 10,
      'impozit': 30,
      'heating': 25,
      'internet': 5,
    };
    final date = DateTime.now().subtract(
      Duration(days: daysAgo[taxType] ?? 15),
    );
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    // Clean up overlays if still showing
    _removeSuccessOverlay();
    _removeErrorOverlay();

    // Dispose text controllers
    for (final controller in _readingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildModal();
  }

  Widget _buildModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // 90% of screen height
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top:
            false, // Don't add top padding since we want the modal to go to the top
        bottom: true, // Add bottom padding to avoid navigation bar
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(
                  AppConfig.textSecondaryColor,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Role details section (compact)
            if (widget.role != null) _buildCompactRoleDetails(),

            // Tax containers
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Show only taxes that exist in the API response
                    if (widget.role != null && widget.role!.tax.isNotEmpty) ...[
                      ...widget.role!.tax.map((tax) {
                        final taxType = _getTaxTypeFromName(tax.numeTaxa);
                        return Column(
                          children: [
                            _buildTaxContainer(
                              tax.numeTaxa, // Use actual tax name from database
                              taxType,
                              _getTaxIcon(taxType),
                              tax.unitMasura,
                              tax:
                                  tax, // Pass tax object to access inactiva and perioada_index
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                    ] else ...[
                      // Fallback to all tax types if no role data
                      _buildTaxContainer(
                        LocalizationService.getString('work.electricity'),
                        'electricity',
                        Icons.electrical_services,
                        'kWh',
                      ),
                      const SizedBox(height: 16),
                      _buildTaxContainer(
                        LocalizationService.getString('work.gas'),
                        'gas',
                        Icons.local_fire_department,
                        'm³',
                      ),
                      const SizedBox(height: 16),
                      _buildTaxContainer(
                        LocalizationService.getString('work.water'),
                        'water',
                        Icons.water_drop,
                        'm³',
                      ),
                      const SizedBox(height: 16),
                      _buildTaxContainer(
                        LocalizationService.getString('work.impozit'),
                        'impozit',
                        Icons.account_balance,
                        'RON',
                      ),
                      const SizedBox(height: 16),
                      _buildTaxContainer(
                        LocalizationService.getString('work.heating'),
                        'heating',
                        Icons.thermostat,
                        'Gcal',
                      ),
                      const SizedBox(height: 16),
                      _buildTaxContainer(
                        LocalizationService.getString('work.internet'),
                        'internet',
                        Icons.wifi,
                        'RON',
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Back button
                    _buildBackButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRoleDetails() {
    final role = widget.role!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConfig.primaryColor).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(
          color: const Color(AppConfig.primaryColor).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home,
            color: const Color(AppConfig.primaryColor),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROL: ${role.rol}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(AppConfig.primaryColor),
                  ),
                ),
                Text(
                  role.addr.fullAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(AppConfig.textColor),
                  ),
                ),
                Text(
                  role.pers.fullName,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(AppConfig.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxContainer(
    String title,
    String taxType,
    IconData icon,
    String unit, {
    Tax? tax, // Optional tax object to access inactiva and perioada_index
  }) {
    final hasError = _fieldErrors[taxType] ?? false;
    final isSaved = _isSaved[taxType] ?? false;
    final isInactive = tax?.isInactive ?? false;
    final perioadaIndex = tax?.perioadaIndex ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isInactive
            ? const Color(AppConfig.errorColor).withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(
          color: hasError
              ? const Color(AppConfig.errorColor)
              : isInactive
                  ? const Color(AppConfig.errorColor).withValues(alpha: 0.5)
                  : const Color(AppConfig.primaryColor).withValues(alpha: 0.1),
          width: hasError
              ? 2
              : isInactive
                  ? 2
                  : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError
                ? const Color(AppConfig.errorColor).withValues(alpha: 0.1)
                : isInactive
                    ? const Color(AppConfig.errorColor).withValues(alpha: 0.15)
                    : const Color(AppConfig.primaryColor)
                        .withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tax header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isInactive
                      ? const Color(AppConfig.errorColor).withValues(alpha: 0.1)
                      : const Color(
                          AppConfig.primaryColor,
                        ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isInactive
                      ? const Color(AppConfig.errorColor)
                      : const Color(AppConfig.primaryColor),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isInactive
                        ? const Color(AppConfig.errorColor)
                        : const Color(AppConfig.textColor),
                  ),
                ),
              ),
              // Inactive badge
              if (isInactive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(AppConfig.errorColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'INACTIVĂ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isSaved && !isInactive)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(AppConfig.successColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        LocalizationService.getString('work.saved'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Perioada Index display
          if (perioadaIndex.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(AppConfig.backgroundColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(AppConfig.primaryColor)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: const Color(AppConfig.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Perioada Index: $perioadaIndex',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConfig.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Last reading info - ALWAYS visible
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(AppConfig.backgroundColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.getString('work.last_reading'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(AppConfig.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        LocalizationService.getString('work.date'),
                        _lastDates[taxType]!,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        LocalizationService.getString('work.type'),
                        _lastTypes[taxType]!,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        LocalizationService.getString('work.value'),
                        '${_lastReadings[taxType]!} $unit',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Current reading form or saved data display
          if (isSaved) ...[
            // Show saved current reading data
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(
                  AppConfig.successColor,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(
                    AppConfig.successColor,
                  ).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: const Color(AppConfig.successColor),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LocalizationService.getString(
                          'work.current_reading_saved',
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConfig.successColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSavedCurrentItem(
                          LocalizationService.getString('work.date'),
                          _savedDates[taxType]!,
                        ),
                      ),
                      Expanded(
                        child: _buildSavedCurrentItem(
                          LocalizationService.getString('work.type'),
                          _savedTypes[taxType]!,
                        ),
                      ),
                      Expanded(
                        child: _buildSavedCurrentItem(
                          LocalizationService.getString('work.value'),
                          '${_savedValues[taxType]!} $unit',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Current reading form
            Text(
              LocalizationService.getString('work.current_reading'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(AppConfig.textColor),
              ),
            ),

            const SizedBox(height: 12),

            // Date picker
            InkWell(
              onTap: () => _selectDate(taxType),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(
                      AppConfig.primaryColor,
                    ).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: const Color(AppConfig.primaryColor),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_readingDates[taxType]!.day}/${_readingDates[taxType]!.month}/${_readingDates[taxType]!.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(AppConfig.textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Reading type dropdown and value input
            Row(
              children: [
                // Type dropdown
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(
                          AppConfig.primaryColor,
                        ).withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _readingTypes[taxType],
                        isExpanded: true,
                        items: [
                          'Citire (C)', // C - Citire (default)
                          'Estimată (E)', // E - Estimat
                          'Paușală (P)', // P - Pausal
                          'Fără facturare (F)', // F - Fara facturare
                          'Neutilizat (X)', // X - Neutilizat inca
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(AppConfig.textColor),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _readingTypes[taxType] = newValue!;
                            // Update the value field when type changes
                            _updateValueForReadingType(taxType);
                          });
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Value input
                Expanded(
                  flex: 1,
                  child: _buildValueInput(taxType, hasError, unit),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveReading(taxType),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        LocalizationService.getString('work.save'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: const Color(AppConfig.textSecondaryColor),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(AppConfig.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(AppConfig.primaryColor),
          side: BorderSide(
            color: const Color(AppConfig.primaryColor),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
        ),
        child: Text(
          LocalizationService.getString('work.back'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _selectDate(String taxType) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _readingDates[taxType]!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Allow future dates up to 1 year
    );

    if (picked != null && picked != _readingDates[taxType]) {
      setState(() {
        _readingDates[taxType] = picked;
      });
    }
  }

  void _saveReading(String taxType) {
    final value = _readingControllers[taxType]!.text.trim();

    // Clear previous errors
    setState(() {
      _fieldErrors[taxType] = false;
    });

    if (value.isEmpty) {
      setState(() {
        _fieldErrors[taxType] = true;
      });
      return;
    }

    // Show confirmation dialog
    _showSaveConfirmation(taxType, value);
  }

  void _showSaveConfirmation(String taxType, String value) async {
    // Get actual tax name from database
    final tax = _findTaxForType(taxType);
    final taxName = tax?.numeTaxa.isNotEmpty == true
        ? tax!.numeTaxa
        : _getTaxTypeTranslation(taxType);

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(
                  AppConfig.primaryColor,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.save_alt,
                color: const Color(AppConfig.primaryColor),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocalizationService.getString(
                  'work.save_reading_title',
                  params: {'type': taxName},
                ),
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
              LocalizationService.getString('work.save_reading_message'),
              style: const TextStyle(
                fontSize: 16,
                color: Color(AppConfig.textColor),
              ),
            ),
            const SizedBox(height: 20),
            _buildModernValueSection(taxType, value),
            const SizedBox(height: 16),
            _buildModernDetailsSection(taxType),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(false);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          ElevatedButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConfig.primaryColor),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              LocalizationService.getString('work.save'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    // Only proceed with save if user confirmed
    if (shouldSave == true) {
      _performSave(taxType, value);
    }
  }

  void _performSave(String taxType, String value) async {
    // Dismiss keyboard before saving
    FocusScope.of(context).unfocus();

    // Show loading state
    setState(() {
      _isSaving = true;
    });

    try {
      // Find the corresponding tax from the role data
      final tax = _findTaxForType(taxType);
      if (tax == null) {
        _showError('Tipul de taxă nu a fost găsit în datele rolului');
        return;
      }

      // Determine the reading type for API
      final apiReadingType = _getApiReadingType(_readingTypes[taxType]!);

      // Handle special case: if P or E is selected, use val_new_p or val_new_e
      String finalValue = value;
      if (apiReadingType == 'P') {
        finalValue = tax.valNewP.toString();
      } else if (apiReadingType == 'E') {
        finalValue = tax.valNewE.toString();
      }

      // Format date for API (YYYY-MM-DD)
      final formattedDate = _formatDateForApi(_readingDates[taxType]!);

      DebugLogger.api('🔐 [WORK_MODAL] Saving reading for tax: $taxType');
      DebugLogger.api('🔐 [WORK_MODAL] Role ID: ${widget.role!.idRol}');
      DebugLogger.api('🔐 [WORK_MODAL] Tax Type ID: ${tax.idTipTaxa}');
      DebugLogger.api('🔐 [WORK_MODAL] Tax2Role ID: ${tax.idTax2rol}');
      DebugLogger.api('🔐 [WORK_MODAL] Tax2Bord ID: ${tax.idTax2bord}');
      DebugLogger.api('🔐 [WORK_MODAL] Value: $finalValue');
      DebugLogger.api('🔐 [WORK_MODAL] Date: $formattedDate');
      DebugLogger.api('🔐 [WORK_MODAL] Type: $apiReadingType');

      // Call API to save reading
      final response = await ApiService.addReading(
        idRol: widget.role!.idRol,
        idTipTaxa: tax.idTipTaxa,
        idTax2rol: tax.idTax2rol,
        idTax2bord: tax.idTax2bord,
        valNew: finalValue,
        dataCitireNew: formattedDate,
        tipCitireOld: apiReadingType,
      );

      if (response.isSuccess) {
        // Success - update UI
        setState(() {
          _isSaved[taxType] = true;
          _savedValues[taxType] = finalValue;
          _savedDates[taxType] =
              '${_readingDates[taxType]!.day}/${_readingDates[taxType]!.month}/${_readingDates[taxType]!.year}';
          _savedTypes[taxType] = _readingTypes[taxType]!;
          _readingControllers[taxType]!.clear();
        });

        // Show success message with actual tax name
        // Display exact success message from API response
        _showSuccessMessage(response.msgErr);

        // Refresh data to get updated values from server
        widget.onDataUpdated?.call();

        DebugLogger.success(
          '✅ [WORK_MODAL] Reading saved successfully: ${response.msgErr}',
        );
      } else {
        // Display exact error message from API response
        _showError(response.msgErr);
        DebugLogger.error('❌ [WORK_MODAL] API error: ${response.msgErr}');
      }
    } catch (e) {
      _showError(ErrorHandlingService.getFriendlyErrorMessage(e));
      DebugLogger.log('❌ [WORK_MODAL] Exception: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildSavedCurrentItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(AppConfig.successColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(AppConfig.textColor),
          ),
        ),
      ],
    );
  }

  String _getTaxTypeTranslation(String taxType) {
    final typeMap = {
      'electricity': 'work.electricity',
      'gas': 'work.gas',
      'water': 'work.water',
      'impozit': 'work.impozit',
      'heating': 'work.heating',
      'internet': 'work.internet',
    };

    final key = typeMap[taxType.toLowerCase()] ?? 'work.electricity';
    return LocalizationService.getString(key);
  }

  /// Map API tax names to internal tax types
  String _getTaxTypeFromName(String taxName) {
    switch (taxName.toLowerCase()) {
      case 'apa':
        return 'water';
      case 'curent':
        return 'electricity';
      case 'gaz':
        return 'gas';
      case 'impozit':
        return 'impozit';
      case 'incalzire':
      case 'heating':
        return 'heating';
      case 'internet':
        return 'internet';
      default:
        return 'electricity'; // Default fallback
    }
  }

  /// Translate API reading types to UI text (for display)
  String _getReadingTypeTranslation(String apiType) {
    switch (apiType.toUpperCase()) {
      case 'C':
        return 'Manuală'; // Citire
      case 'E':
        return 'Estimată'; // Estimat
      case 'P':
        return 'Paușală'; // Pausal
      case 'F':
        return 'Fără facturare'; // Fara facturare
      case 'X':
        return 'Neutilizat'; // Neutilizat
      default:
        return 'Manuală';
    }
  }

  /// Format API date to display format
  String _formatDate(String apiDate) {
    if (apiDate == '0000-00-00' || apiDate.isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(apiDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return apiDate; // Return as-is if parsing fails
    }
  }

  /// Get icon for tax type
  IconData _getTaxIcon(String taxType) {
    switch (taxType) {
      case 'water':
        return Icons.water_drop;
      case 'electricity':
        return Icons.electrical_services;
      case 'gas':
        return Icons.local_fire_department;
      case 'impozit':
        return Icons.account_balance;
      case 'heating':
        return Icons.thermostat;
      case 'internet':
        return Icons.wifi;
      default:
        return Icons.receipt;
    }
  }

  /// Find tax data for the given tax type
  Tax? _findTaxForType(String taxType) {
    if (widget.role == null) return null;

    for (final tax in widget.role!.tax) {
      final mappedType = _getTaxTypeFromName(tax.numeTaxa);
      if (mappedType == taxType) {
        return tax;
      }
    }
    return null;
  }

  /// Convert UI reading type to API reading type
  String _getApiReadingType(String uiType) {
    if (uiType.contains('(C)')) return 'C';
    if (uiType.contains('(E)')) return 'E';
    if (uiType.contains('(P)')) return 'P';
    if (uiType.contains('(F)')) return 'F';
    if (uiType.contains('(X)')) return 'X';
    return 'C'; // Default to Citire
  }

  /// Convert API reading type to UI reading type
  String _getUIReadingType(String apiType) {
    switch (apiType.toUpperCase()) {
      case 'C':
        return 'Citire (C)';
      case 'E':
        return 'Estimată (E)';
      case 'P':
        return 'Paușală (P)';
      case 'F':
        return 'Fără facturare (F)';
      case 'X':
        return 'Neutilizat (X)';
      default:
        return 'Citire (C)';
    }
  }

  /// Format date for API (YYYY-MM-DD)
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Show error message
  void _showError(String message) {
    // Remove existing overlays if any
    _removeSuccessOverlay();
    _removeErrorOverlay();

    // Create overlay entry to show error above modal
    _errorOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(AppConfig.errorColor),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_errorOverlay!);

    // Remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _removeErrorOverlay();
    });
  }

  void _removeErrorOverlay() {
    _errorOverlay?.remove();
    _errorOverlay = null;
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    // Remove existing overlays if any
    _removeSuccessOverlay();
    _removeErrorOverlay();

    // Create overlay entry to show message above modal
    _successOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(AppConfig.successColor),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_successOverlay!);

    // Remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      _removeSuccessOverlay();
    });
  }

  void _removeSuccessOverlay() {
    _successOverlay?.remove();
    _successOverlay = null;
  }

  /// Update value field when reading type changes
  void _updateValueForReadingType(String taxType) {
    final readingType = _readingTypes[taxType] ?? 'Citire (C)';

    if (widget.role != null) {
      final tax = _findTaxForType(taxType);
      if (tax != null) {
        String? newValue;

        if (readingType.contains('(E)')) {
          // E - Estimată → use val_new_e
          newValue = tax.valNewE.toString();
        } else if (readingType.contains('(P)')) {
          // P - Paușală → use val_new_p
          newValue = tax.valNewP.toString();
        } else if (readingType.contains('(F)')) {
          // F - Fără facturare → use val_old
          newValue = tax.valOld.toString();
        } else if (readingType.contains('(C)') || readingType.contains('(X)')) {
          // C - Citire or X - Neutilizat → empty
          newValue = '';
        }

        // Update the controller with the new value
        if (newValue != null) {
          _readingControllers[taxType]?.text = newValue;
        }
      }
    }
  }

  /// Build value input with automatic handling for P, E, and F types
  Widget _buildValueInput(String taxType, bool hasError, String unit) {
    final readingType = _readingTypes[taxType] ?? 'Citire (C)';

    return TextField(
      controller: _readingControllers[taxType],
      enabled: true, // Always enabled - user can edit even automatic values
      decoration: InputDecoration(
        hintText: (readingType.contains('(E)') ||
                readingType.contains('(P)') ||
                readingType.contains('(F)'))
            ? 'Valoare'
            : LocalizationService.getString('work.enter_value'),
        hintStyle: TextStyle(
          color: hasError
              ? const Color(AppConfig.errorColor).withValues(alpha: 0.6)
              : (readingType.contains('(E)') ||
                      readingType.contains('(P)') ||
                      readingType.contains('(F)'))
                  ? const Color(AppConfig.primaryColor).withValues(alpha: 0.7)
                  : null,
        ),
        suffixText: ' $unit', // Always show unit for all reading types
        suffixStyle: TextStyle(
          color: const Color(AppConfig.primaryColor).withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError
                ? const Color(AppConfig.errorColor)
                : (readingType.contains('(E)') ||
                        readingType.contains('(P)') ||
                        readingType.contains('(F)'))
                    ? const Color(AppConfig.primaryColor).withValues(alpha: 0.5)
                    : const Color(AppConfig.primaryColor)
                        .withValues(alpha: 0.3),
            width: hasError ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError
                ? const Color(AppConfig.errorColor)
                : (readingType.contains('(E)') ||
                        readingType.contains('(P)') ||
                        readingType.contains('(F)'))
                    ? const Color(AppConfig.primaryColor).withValues(alpha: 0.5)
                    : const Color(AppConfig.primaryColor)
                        .withValues(alpha: 0.3),
            width: hasError ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError
                ? const Color(AppConfig.errorColor)
                : const Color(AppConfig.primaryColor),
            width: hasError ? 2 : 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        fillColor: (readingType.contains('(E)') ||
                readingType.contains('(P)') ||
                readingType.contains('(F)'))
            ? const Color(AppConfig.primaryColor).withValues(alpha: 0.05)
            : null,
        filled: (readingType.contains('(E)') ||
            readingType.contains('(P)') ||
            readingType.contains('(F)')),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        // Clear error when user starts typing
        if (hasError && value.isNotEmpty) {
          setState(() {
            _fieldErrors[taxType] = false;
          });
        }
      },
    );
  }

  /// Build modern value section with tax, old value, new value, and difference
  Widget _buildModernValueSection(String taxType, String newValue) {
    final tax = _findTaxForType(taxType);
    if (tax == null) return const SizedBox.shrink();

    final oldValue = tax.valOld;
    final newValueInt = int.tryParse(newValue) ?? 0;
    final difference = newValueInt - oldValue;
    final unit = tax.unitMasura;
    // Use actual tax name from database
    final taxName = tax.numeTaxa.isNotEmpty
        ? tax.numeTaxa
        : _getTaxTypeTranslation(taxType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(AppConfig.backgroundColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppConfig.primaryColor).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tax Type - Left aligned
          Row(
            children: [
              Icon(
                Icons.receipt,
                size: 18,
                color: const Color(AppConfig.primaryColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Taxa:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(AppConfig.textSecondaryColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                taxName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(AppConfig.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Old Value
          _buildSimpleValueRow(
            'Valoare anterioară:',
            '$oldValue $unit',
            Icons.history,
          ),
          const SizedBox(height: 8),

          // New Value
          _buildSimpleValueRow(
            'Valoare curentă:',
            '$newValue $unit',
            Icons.edit,
          ),

          const SizedBox(height: 12),

          // Difference (subtle)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: difference >= 0
                    ? const Color(AppConfig.successColor).withValues(alpha: 0.1)
                    : const Color(AppConfig.warningColor)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: difference >= 0
                      ? const Color(AppConfig.successColor)
                          .withValues(alpha: 0.3)
                      : const Color(AppConfig.warningColor)
                          .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    difference >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: difference >= 0
                        ? const Color(AppConfig.successColor)
                        : const Color(AppConfig.warningColor),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${difference >= 0 ? '+' : ''}$difference $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: difference >= 0
                          ? const Color(AppConfig.successColor)
                          : const Color(AppConfig.warningColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build modern details section with date and reading type
  Widget _buildModernDetailsSection(String taxType) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConfig.backgroundColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppConfig.primaryColor).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildModernInfoRow(
            'Data:',
            '${_readingDates[taxType]!.day}/${_readingDates[taxType]!.month}/${_readingDates[taxType]!.year}',
            Icons.calendar_today,
            const Color(AppConfig.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          _buildModernInfoRow(
            'Tip citire:',
            _readingTypes[taxType]!,
            Icons.category,
            const Color(AppConfig.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  /// Build simple value row with icon, label and value
  Widget _buildSimpleValueRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(AppConfig.textSecondaryColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(AppConfig.textSecondaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(AppConfig.textColor),
          ),
        ),
      ],
    );
  }

  /// Build modern info row with icon and text
  Widget _buildModernInfoRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(AppConfig.textSecondaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(AppConfig.textColor),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
