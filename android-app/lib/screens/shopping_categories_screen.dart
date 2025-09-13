import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';
import '../providers/shopping_providers.dart';

/// T095 - Shopping Categories Screen
/// Gestione e visualizzazione delle categorie shopping con filtri avanzati
class ShoppingCategoriesScreen extends ConsumerStatefulWidget {
  const ShoppingCategoriesScreen({super.key});

  @override
  ConsumerState<ShoppingCategoriesScreen> createState() => _ShoppingCategoriesScreenState();
}

class _ShoppingCategoriesScreenState extends ConsumerState<ShoppingCategoriesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorie Shopping'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.list : Icons.analytics),
            onPressed: () => setState(() => _showStats = !_showStats),
            tooltip: _showStats ? 'Mostra Categorie' : 'Mostra Statistiche',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Gestisci Categorie'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Reset Filtri'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tutte', icon: Icon(Icons.category, size: 20)),
            Tab(text: 'Preferite', icon: Icon(Icons.star, size: 20)),
            Tab(text: 'Recenti', icon: Icon(Icons.access_time, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (!_showStats) _buildCategoryFilter(selectedCategory),
          Expanded(
            child: _showStats 
              ? _buildStatsView(shoppingLists)
              : _buildCategoriesView(shoppingLists, selectedCategory),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCategoryDialog(),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cerca categorie o prodotti...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCategoryFilter(ShoppingCategory? selectedCategory) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ShoppingCategory.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip(
              label: 'Tutte',
              isSelected: selectedCategory == null,
              onTap: () => ref.read(categoryFilterProvider.notifier).clearFilter(),
              icon: Icons.apps,
            );
          }
          
          final category = ShoppingCategory.values[index - 1];
          return _buildCategoryChip(
            label: _getCategoryDisplayName(category),
            isSelected: selectedCategory == category,
            onTap: () => ref.read(categoryFilterProvider.notifier).setFilter(category),
            icon: _getCategoryIcon(category),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.blue[600],
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCategoriesView(List<ShoppingList> shoppingLists, ShoppingCategory? selectedCategory) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCategoryList(shoppingLists, selectedCategory, CategoryFilter.all),
        _buildCategoryList(shoppingLists, selectedCategory, CategoryFilter.favorites),
        _buildCategoryList(shoppingLists, selectedCategory, CategoryFilter.recent),
      ],
    );
  }

  Widget _buildCategoryList(List<ShoppingList> shoppingLists, ShoppingCategory? selectedCategory, CategoryFilter filter) {
    final filteredCategories = _getFilteredCategories(shoppingLists, selectedCategory, filter);
    
    if (filteredCategories.isEmpty) {
      return _buildEmptyState(filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final categoryData = filteredCategories[index];
        return _buildCategoryCard(categoryData, shoppingLists);
      },
    );
  }

  Widget _buildCategoryCard(CategoryData categoryData, List<ShoppingList> shoppingLists) {
    final category = categoryData.category;
    final items = _getItemsForCategory(shoppingLists, category);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToCategoryDetails(category),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryDisplayName(category),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${items.length} prodotti',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryData.usageCount}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 30,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.take(5).length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                if (items.length > 5) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${items.length - 5} altri',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsView(List<ShoppingList> shoppingLists) {
    final stats = _calculateCategoryStats(shoppingLists);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiche Categorie',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatsCards(stats),
          const SizedBox(height: 20),
          _buildCategoryChart(stats),
          const SizedBox(height: 20),
          _buildTopCategories(stats),
        ],
      ),
    );
  }

  Widget _buildStatsCards(CategoryStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Totale Categorie',
            '${stats.totalCategories}',
            Icons.category,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Più Utilizzata',
            _getCategoryDisplayName(stats.mostUsedCategory),
            Icons.trending_up,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(CategoryStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribuzione per Categoria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...stats.categoryUsage.entries.map((entry) {
              final percentage = (entry.value / stats.totalItems * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_getCategoryDisplayName(entry.key)),
                        Text('${percentage.toStringAsFixed(1)}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(_getCategoryColor(entry.key)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(CategoryStats stats) {
    final sortedCategories = stats.categoryUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Categorie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              final index = sortedCategories.indexOf(entry);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(entry.key).withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: _getCategoryColor(entry.key),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(_getCategoryDisplayName(entry.key)),
                subtitle: Text('${entry.value} prodotti'),
                trailing: Icon(
                  _getCategoryIcon(entry.key),
                  color: _getCategoryColor(entry.key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(CategoryFilter filter) {
    String message;
    IconData icon;
    
    switch (filter) {
      case CategoryFilter.favorites:
        message = 'Nessuna categoria preferita';
        icon = Icons.star_border;
        break;
      case CategoryFilter.recent:
        message = 'Nessuna categoria recente';
        icon = Icons.access_time;
        break;
      default:
        message = 'Nessuna categoria trovata';
        icon = Icons.category;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea la tua prima lista shopping per iniziare',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getCategoryDisplayName(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return 'Alimentari';
      case ShoppingCategory.household:
        return 'Casa';
      case ShoppingCategory.personal:
        return 'Personale';
      case ShoppingCategory.electronics:
        return 'Elettronica';
      case ShoppingCategory.clothing:
        return 'Abbigliamento';
      case ShoppingCategory.health:
        return 'Salute';
      case ShoppingCategory.other:
        return 'Altro';
    }
  }

  IconData _getCategoryIcon(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return Icons.shopping_cart;
      case ShoppingCategory.household:
        return Icons.home;
      case ShoppingCategory.personal:
        return Icons.person;
      case ShoppingCategory.electronics:
        return Icons.devices;
      case ShoppingCategory.clothing:
        return Icons.checkroom;
      case ShoppingCategory.health:
        return Icons.local_hospital;
      case ShoppingCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return Colors.green;
      case ShoppingCategory.household:
        return Colors.blue;
      case ShoppingCategory.personal:
        return Colors.purple;
      case ShoppingCategory.electronics:
        return Colors.orange;
      case ShoppingCategory.clothing:
        return Colors.pink;
      case ShoppingCategory.health:
        return Colors.red;
      case ShoppingCategory.other:
        return Colors.grey;
    }
  }

  List<CategoryData> _getFilteredCategories(List<ShoppingList> shoppingLists, ShoppingCategory? selectedCategory, CategoryFilter filter) {
    final Map<ShoppingCategory, int> categoryUsage = {};
    
    // Calculate usage for each category
    for (final list in shoppingLists) {
      for (final item in list.items) {
        categoryUsage[item.category] = (categoryUsage[item.category] ?? 0) + 1;
      }
    }

    final categories = selectedCategory != null 
        ? [selectedCategory]
        : ShoppingCategory.values;

    final categoryDataList = categories.map((category) {
      return CategoryData(
        category: category,
        usageCount: categoryUsage[category] ?? 0,
        lastUsed: DateTime.now(), // Placeholder - would be calculated from actual data
        isFavorite: false, // Placeholder - would come from user preferences
      );
    }).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      return categoryDataList.where((data) {
        final categoryName = _getCategoryDisplayName(data.category).toLowerCase();
        final items = _getItemsForCategory(shoppingLists, data.category);
        final itemNames = items.map((item) => item.name.toLowerCase()).join(' ');
        return categoryName.contains(_searchQuery.toLowerCase()) || 
               itemNames.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply tab filter
    switch (filter) {
      case CategoryFilter.favorites:
        return categoryDataList.where((data) => data.isFavorite).toList();
      case CategoryFilter.recent:
        categoryDataList.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        return categoryDataList.take(5).toList();
      default:
        categoryDataList.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        return categoryDataList;
    }
  }

  List<ShoppingItem> _getItemsForCategory(List<ShoppingList> shoppingLists, ShoppingCategory category) {
    final items = <ShoppingItem>[];
    for (final list in shoppingLists) {
      items.addAll(list.items.where((item) => item.category == category));
    }
    return items;
  }

  CategoryStats _calculateCategoryStats(List<ShoppingList> shoppingLists) {
    final Map<ShoppingCategory, int> categoryUsage = {};
    int totalItems = 0;

    for (final list in shoppingLists) {
      for (final item in list.items) {
        categoryUsage[item.category] = (categoryUsage[item.category] ?? 0) + 1;
        totalItems++;
      }
    }

    final mostUsedCategory = categoryUsage.entries
        .fold<MapEntry<ShoppingCategory, int>?>(null, (prev, current) {
      if (prev == null || current.value > prev.value) {
        return current;
      }
      return prev;
    })?.key ?? ShoppingCategory.groceries;

    return CategoryStats(
      totalCategories: categoryUsage.keys.length,
      totalItems: totalItems,
      categoryUsage: categoryUsage,
      mostUsedCategory: mostUsedCategory,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'manage':
        _showManageCategoriesDialog();
        break;
      case 'reset':
        ref.read(categoryFilterProvider.notifier).clearFilter();
        setState(() => _searchQuery = '');
        break;
    }
  }

  void _showCreateCategoryDialog() {
    // Placeholder for custom category creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funzionalità di creazione categorie personalizzate in arrivo!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestisci Categorie'),
        content: const Text('Funzionalità di gestione categorie personalizzate in arrivo!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToCategoryDetails(ShoppingCategory category) {
    Navigator.of(context).pushNamed(
      '/shopping-category-details',
      arguments: category,
    );
  }
}

// Data classes per gestione categorie
class CategoryData {
  final ShoppingCategory category;
  final int usageCount;
  final DateTime lastUsed;
  final bool isFavorite;

  CategoryData({
    required this.category,
    required this.usageCount,
    required this.lastUsed,
    required this.isFavorite,
  });
}

class CategoryStats {
  final int totalCategories;
  final int totalItems;
  final Map<ShoppingCategory, int> categoryUsage;
  final ShoppingCategory mostUsedCategory;

  CategoryStats({
    required this.totalCategories,
    required this.totalItems,
    required this.categoryUsage,
    required this.mostUsedCategory,
  });
}

enum CategoryFilter { all, favorites, recent }