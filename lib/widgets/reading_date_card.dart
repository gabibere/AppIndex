import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/reading_date_provider.dart';

class ReadingDateCard extends StatelessWidget {
  const ReadingDateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingDateProvider>(
      builder: (context, readingDateProvider, child) {
        return Card(
          elevation: 6,
          shadowColor:
              const Color(AppConfig.primaryColor).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(AppConfig.primaryColor).withValues(alpha: 0.05),
                  const Color(AppConfig.secondaryColor).withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(AppConfig.primaryColor)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(AppConfig.primaryColor),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Citirii',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(AppConfig.textColor),
                              ),
                            ),
                            Text(
                              readingDateProvider.getRelativeDescription(),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    const Color(AppConfig.textSecondaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Current date display
                  InkWell(
                    onTap: () => _showDatePicker(context),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: const Color(AppConfig.primaryColor)
                        .withValues(alpha: 0.1),
                    highlightColor: const Color(AppConfig.primaryColor)
                        .withValues(alpha: 0.05),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(AppConfig.backgroundColor),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(AppConfig.primaryColor)
                              .withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: const Color(AppConfig.primaryColor),
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            readingDateProvider.formattedDate,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(AppConfig.textColor),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(AppConfig.primaryColor)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getDayOfWeek(readingDateProvider.selectedDate),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(AppConfig.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: const Color(AppConfig.primaryColor)
                                .withValues(alpha: 0.6),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _QuickDateButton(
                          label: 'Ieri',
                          isSelected: readingDateProvider.isYesterday(),
                          onTap: () => readingDateProvider.setYesterday(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickDateButton(
                          label: 'Astăzi',
                          isSelected: readingDateProvider.isToday(),
                          onTap: () => readingDateProvider.setToday(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickDateButton(
                          label: 'Mâine',
                          isSelected: readingDateProvider.isTomorrow(),
                          onTap: () => readingDateProvider.setTomorrow(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDatePicker(BuildContext context) {
    final readingDateProvider =
        Provider.of<ReadingDateProvider>(context, listen: false);

    showDatePicker(
      context: context,
      initialDate: readingDateProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ro', 'RO'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(AppConfig.primaryColor),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(AppConfig.textColor),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(AppConfig.primaryColor),
              ),
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        readingDateProvider.setDate(selectedDate);
      }
    });
  }

  String _getDayOfWeek(DateTime date) {
    const days = [
      'Luni',
      'Marți',
      'Miercuri',
      'Joi',
      'Vineri',
      'Sâmbătă',
      'Duminică'
    ];
    return days[date.weekday - 1];
  }
}

class _QuickDateButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(AppConfig.primaryColor)
              : const Color(AppConfig.backgroundColor),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(AppConfig.primaryColor)
                : const Color(AppConfig.secondaryColor).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(AppConfig.textColor),
          ),
        ),
      ),
    );
  }
}
