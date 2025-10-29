import 'package:flutter/foundation.dart';
import '../models/role.dart';
import '../services/api_service.dart';
import '../services/error_handling_service.dart';
import '../utils/debug_logger.dart';

class SearchProvider with ChangeNotifier {
  List<Role> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedLocation;
  String? _error;
  bool _hasMoreData = true;
  bool _hasSearched = false; // Track if a search has been performed

  // Getters
  List<Role> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String? get selectedLocation => _selectedLocation;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  bool get hasSearched => _hasSearched;

  // Search methods
  Future<void> search({
    required String idLoc,
    required String str,
    required String nrDom,
    required String rol,
    bool clearPrevious = true,
  }) async {
    DebugLogger.search('🔍 [SEARCH_PROVIDER] Search called with:');
    DebugLogger.search('🔍 [SEARCH_PROVIDER] idLoc: "$idLoc"');
    DebugLogger.search('🔍 [SEARCH_PROVIDER] str: "$str"');
    DebugLogger.search('🔍 [SEARCH_PROVIDER] nrDom: "$nrDom"');
    DebugLogger.search('🔍 [SEARCH_PROVIDER] rol: "$rol"');

    _isSearching = true;
    _hasSearched = true; // Mark that a search has been performed
    _clearError();

    if (clearPrevious) {
      _searchResults.clear();
      _hasMoreData = true;
    }

    notifyListeners();

    try {
      DebugLogger.api('🔍 [SEARCH_PROVIDER] Initializing API service...');
      // Initialize API service if not already done
      if (!ApiService.isInitialized) {
        ApiService.initialize();
      }

      DebugLogger.search(
        '🔍 [SEARCH_PROVIDER] Calling ApiService.searchRoles...',
      );
      // Search using the roles endpoint
      final response = await ApiService.searchRoles(
        idLoc: idLoc,
        str: str,
        nrDom: nrDom,
        rol: rol,
      );
      DebugLogger.api(
        '🔍 [SEARCH_PROVIDER] API call completed, response received',
      );

      if (response.isSuccess) {
        DebugLogger.success(
          '🔍 [SEARCH_PROVIDER] Search successful! Found ${response.countRoles} roles',
        );
        DebugLogger.search(
          '🔍 [SEARCH_PROVIDER] Response data: ${response.date.length} items',
        );

        if (clearPrevious) {
          _searchResults = response.date;
        } else {
          _searchResults.addAll(response.date);
        }
        _hasMoreData = response.date.length >= 20; // Assuming 20 items per page

        DebugLogger.search(
          '🔍 [SEARCH_PROVIDER] Updated search results: ${_searchResults.length} total items',
        );
      } else {
        DebugLogger.search(
          '🔍 [SEARCH_PROVIDER] Search failed: ${response.msgErr}',
        );
        _setError(
          ErrorHandlingService.getApiErrorMessage({
            'err': response.err,
            'msg_err': response.msgErr,
          }),
        );
      }
    } catch (e) {
      _setError(ErrorHandlingService.getFriendlyErrorMessage(e));
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Load more results
  Future<void> loadMore({
    required String idLoc,
    required String str,
    required String nrDom,
    required String rol,
  }) async {
    if (!_hasMoreData || _isSearching) return;
    await search(
      idLoc: idLoc,
      str: str,
      nrDom: nrDom,
      rol: rol,
      clearPrevious: false,
    );
  }

  // Set location filter
  void setLocation(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchResults.clear();
    _searchQuery = '';
    _selectedLocation = null;
    _hasMoreData = true;
    _hasSearched = false; // Reset search flag when clearing
    _clearError();
    notifyListeners();
  }

  // Add reading
  Future<bool> addReading({
    required int idRol,
    required int idTipTaxa,
    required int idTax2rol,
    required int idTax2bord,
    required String valNew,
    required String dataCitireNew,
    required String tipCitireOld,
  }) async {
    _setLoading(true);
    try {
      // Initialize API service if not already done
      if (!ApiService.isInitialized) {
        ApiService.initialize();
      }

      final response = await ApiService.addReading(
        idRol: idRol,
        idTipTaxa: idTipTaxa,
        idTax2rol: idTax2rol,
        idTax2bord: idTax2bord,
        valNew: valNew,
        dataCitireNew: dataCitireNew,
        tipCitireOld: tipCitireOld,
      );

      if (response.isSuccess) {
        return true;
      } else {
        _setError(response.msgErr);
        return false;
      }
    } catch (e) {
      _setError('Eroare la salvarea citirii: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
