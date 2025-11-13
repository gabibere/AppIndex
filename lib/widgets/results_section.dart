import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/role.dart';
import '../services/localization_service.dart';
import 'work_modal.dart';

class ResultsSection extends StatelessWidget {
  final List<Role> roles;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final bool hasSearched;
  final VoidCallback? onDataRefresh;
  final bool hasMoreResultsToDisplay;
  final int totalResultsCount;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const ResultsSection({
    super.key,
    required this.roles,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.hasSearched = false,
    this.onDataRefresh,
    this.hasMoreResultsToDisplay = false,
    this.totalResultsCount = 0,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    // Always show loading state when loading (even if there are previous results)
    if (isLoading) {
      return _buildLoadingState();
    }

    if (error != null) {
      return _buildErrorState(context);
    }

    // Only show empty state if a search has been performed
    if (hasSearched && roles.isEmpty) {
      return _buildEmptyState();
    }

    // If no search has been performed, don't show anything
    if (!hasSearched) {
      return const SizedBox.shrink();
    }

    return _buildResultsList();
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 4,
      shadowColor: const Color(AppConfig.primaryColor).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(AppConfig.primaryColor)),
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.getString('results.searching'),
              style: const TextStyle(
                color: Color(AppConfig.textSecondaryColor),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: const Color(AppConfig.errorColor).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: const Color(AppConfig.errorColor),
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(AppConfig.textColor),
              ),
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                ),
                child:
                    Text(LocalizationService.getString('location.try_again')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      shadowColor: const Color(AppConfig.primaryColor).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: const Color(AppConfig.textSecondaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.getString('results.no_properties'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.textColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.getString('results.no_properties_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(AppConfig.textSecondaryColor),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Row(
          children: [
            Icon(
              Icons.search,
              color: const Color(AppConfig.primaryColor),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              LocalizationService.getString('results.search_results'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.textColor),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    const Color(AppConfig.primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                totalResultsCount > 0
                    ? '$totalResultsCount ${LocalizationService.getString('results.found')}'
                    : '${roles.length} ${LocalizationService.getString('results.found')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(AppConfig.primaryColor),
                ),
              ),
            ),
          ],
        ),

        // Results list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: roles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _RoleCard(
              role: roles[index],
              onDataRefresh: onDataRefresh,
            );
          },
        ),

        // Show more button or loading indicator (if there are more results to display)
        if (hasMoreResultsToDisplay && onLoadMore != null) ...[
          const SizedBox(height: 16),
          if (isLoadingMore)
            // Loading indicator when loading more
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppConfig.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    LocalizationService.getString('results.loading_more'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(AppConfig.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            )
          else
            // Show more button
            Center(
              child: ElevatedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more, size: 20),
                label: Text(
                  LocalizationService.getString('results.show_more'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (!isLoadingMore)
            Text(
              '${roles.length} / $totalResultsCount ${LocalizationService.getString('results.displayed')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(AppConfig.textSecondaryColor),
              ),
            ),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Role role;
  final VoidCallback? onDataRefresh;

  const _RoleCard({required this.role, this.onDataRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: const Color(AppConfig.primaryColor).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: InkWell(
        onTap: () => _onRoleTap(context),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with Rol
              Row(
                children: [
                  // Rol badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(AppConfig.primaryColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ROL: ${role.rol}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(AppConfig.primaryColor),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Person type
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(AppConfig.accentColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role.pers.isPhysicalPerson ? 'PF' : 'PJ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(AppConfig.accentColor),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: const Color(AppConfig.textSecondaryColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      role.addr.fullAddress,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(AppConfig.textColor),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Owner name
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: const Color(AppConfig.textSecondaryColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      role.pers.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(AppConfig.textSecondaryColor),
                      ),
                    ),
                  ),
                ],
              ),

              // Tax info
              if (role.tax.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      size: 14,
                      color: const Color(AppConfig.textSecondaryColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${role.tax.length} taxe',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(AppConfig.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onRoleTap(BuildContext context) {
    // Show work modal with role details
    _showWorkModal(context);
  }

  void _showWorkModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: false,
      builder: (context) => WorkModal(
        role: role,
        onDataUpdated: onDataRefresh,
      ),
    );
  }
}
