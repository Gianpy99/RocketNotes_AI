import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../services/family_cache_service.dart';

/// Performance optimization service for family operations
class FamilyPerformanceService {
  final FamilyCacheService _cacheService;

  FamilyPerformanceService(this._cacheService);

  /// Optimized family data loading with caching
  Future<T> loadWithCache<T>({
    required String cacheKey,
    required Future<T> Function() fetchFromNetwork,
    required Future<void> Function(T) saveToCache,
    T? Function()? getFromCache,
    Duration? cacheDuration,
  }) async {
    // Try to get from cache first
    if (getFromCache != null) {
      final cachedData = getFromCache.call();
      if (cachedData != null) {
        debugPrint('Loaded $cacheKey from cache');
        return cachedData;
      }
    }

    // Fetch from network
    debugPrint('Fetching $cacheKey from network');
    final networkData = await fetchFromNetwork();

    // Save to cache for future use
    await saveToCache(networkData);

    return networkData;
  }

  /// Batch operations to reduce network calls
  Future<List<T>> batchLoad<T>({
    required List<String> ids,
    required Future<T> Function(String) fetchSingle,
    int batchSize = 5,
  }) async {
    final results = <T>[];

    for (var i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();
      final batchFutures = batch.map(fetchSingle);
      final batchResults = await Future.wait(batchFutures);
      results.addAll(batchResults);

      // Small delay to prevent overwhelming the server
      if (i + batchSize < ids.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Debounced search to reduce API calls
  Future<List<T>> debouncedSearch<T>({
    required String query,
    required Future<List<T>> Function(String) searchFunction,
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) async {
    await Future.delayed(debounceDuration);
    return searchFunction(query);
  }

  /// Preload commonly accessed data
  Future<void> preloadCommonData(String familyId) async {
    try {
      // This would preload frequently accessed family data
      // Implementation depends on specific use case
      debugPrint('Preloading common data for family: $familyId');
    } catch (e) {
      debugPrint('Error preloading data: $e');
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'cache_stats': _cacheService.getCacheStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider for performance service
final familyPerformanceServiceProvider = Provider<FamilyPerformanceService>((ref) {
  final cacheService = FamilyCacheService();
  return FamilyPerformanceService(cacheService);
});

/// Loading state widget for better UX
class OptimizedLoadingWidget extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;

  const OptimizedLoadingWidget({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Stack(
      children: [
        child,
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loadingMessage ?? 'Loading...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lazy loading list view for large datasets
class LazyLoadingListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int, int) loadData;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int pageSize;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const LazyLoadingListView({
    super.key,
    required this.loadData,
    required this.itemBuilder,
    this.pageSize = 20,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMoreData();
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.loadData(_currentPage, widget.pageSize);

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMoreData = newItems.length >= widget.pageSize;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ?? Center(child: Text('Error: $_error'));
    }

    return ListView.builder(
      itemCount: _items.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          // Loading indicator
          if (_isLoading) {
            return widget.loadingWidget ??
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
          }

          // Load more trigger (invisible)
          _loadMoreData();
          return const SizedBox.shrink();
        }

        return widget.itemBuilder(context, _items[index], index);
      },
    );
  }
}
