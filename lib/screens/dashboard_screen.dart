import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/search_section.dart';
import '../widgets/results_section.dart';
import '../widgets/reading_date_card.dart';
import '../services/localization_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late ScrollController _scrollController;
  final GlobalKey _resultsSectionKey = GlobalKey();
  final GlobalKey _searchSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _slideController.forward();
  }

  void _scrollToResults() {
    // Wait a bit for the results to render, then scroll to top
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_resultsSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsSectionKey.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          alignment: 0.0, // Scroll so results section is at the very top
        );
      } else if (_scrollController.hasClients) {
        // Fallback: scroll to top of the scroll view
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _performDataRefresh(SearchProvider searchProvider) {
    // Refresh data by calling the refresh method
    searchProvider.refreshData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Color(AppConfig.primaryColor)),
            const SizedBox(width: 8),
            Text(LocalizationService.getString('auth.confirm_logout')),
          ],
        ),
        content: Text(LocalizationService.getString('auth.logout_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              LocalizationService.getString('auth.cancel'),
              style: const TextStyle(
                color: Color(AppConfig.textSecondaryColor),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConfig.errorColor),
              foregroundColor: Colors.white,
            ),
            child: Text(
              LocalizationService.getString('auth.logout'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    // Only proceed with logout if user confirmed
    if (shouldLogout == true) {
      // Dismiss keyboard before navigation
      FocusScope.of(context).unfocus();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundColor),
      extendBody: true, // Allow content to extend behind system UI
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeController, _slideController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildDashboard(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // App Bar
        _buildAppBar(),

        // Main Content
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Reading Date Card
                const ReadingDateCard(),

                const SizedBox(height: 20),

                // Search Section
                SearchSection(
                  key: _searchSectionKey,
                  onSearchTriggered: _scrollToResults,
                ),

                const SizedBox(height: 24),

                // Results Section
                Consumer<SearchProvider>(
                  builder: (context, searchProvider, child) {
                    return ResultsSection(
                      key: _resultsSectionKey,
                      roles: searchProvider.displayedResults,
                      isLoading: searchProvider.isSearching,
                      error: searchProvider.error,
                      hasSearched: searchProvider.hasSearched,
                      hasMoreResultsToDisplay:
                          searchProvider.hasMoreResultsToDisplay,
                      totalResultsCount: searchProvider.totalResultsCount,
                      isLoadingMore: searchProvider.isLoadingMore,
                      onRetry: () {
                        // Retry with last search parameters if available
                        // You may need to store search parameters in SearchProvider
                      },
                      onDataRefresh: () {
                        // Refresh data by performing the same search again
                        _performDataRefresh(searchProvider);
                      },
                      onLoadMore: () {
                        searchProvider.loadMoreResults();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConfig.primaryColor),
            Color(AppConfig.secondaryColor),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User info
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            user?.initials ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizationService.getString('auth.welcome'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              user?.displayName ??
                                  LocalizationService.getString('auth.user'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Action buttons
              Row(
                children: [
                  // Logout button
                  IconButton(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: LocalizationService.getString('auth.logout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
