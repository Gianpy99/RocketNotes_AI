// lib/ui/widgets/search/advanced_search_bar.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdvancedSearchBar extends StatefulWidget {
  final String? initialQuery;
  final List<String> selectedTags;
  final List<String> availableTags;
  final DateTimeRange? dateRange;
  final Function(String query, List<String> tags, DateTimeRange? dateRange) onSearch;
  final VoidCallback? onClear;

  const AdvancedSearchBar({
    super.key,
    this.initialQuery,
    this.selectedTags = const [],
    this.availableTags = const [],
    this.dateRange,
    required this.onSearch,
    this.onClear,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  List<String> _selectedTags = [];
  DateTimeRange? _selectedDateRange;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _selectedTags = List.from(widget.selectedTags);
    _selectedDateRange = widget.dateRange;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _performSearch() {
    widget.onSearch(
      _searchController.text,
      _selectedTags,
      _selectedDateRange,
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _selectedTags.clear();
      _selectedDateRange = null;
    });
    widget.onClear?.call();
  }

  void _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (dateRange != null) {
      setState(() {
        _selectedDateRange = dateRange;
      });
      _performSearch();
    }
  }

  bool get _hasActiveFilters =>
      _selectedTags.isNotEmpty || _selectedDateRange != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? AppColors.surfaceDark.withOpacity(0.9)
          : AppColors.surfaceLight.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode 
                        ? Colors.grey[800]
                        : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _clearSearch();
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Filter Toggle Button
                IconButton(
                  onPressed: _toggleExpanded,
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.tune_rounded,
                      color: _hasActiveFilters ? AppColors.primary : null,
                    ),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _hasActiveFilters 
                      ? AppColors.primary.withOpacity(0.1)
                      : null,
                  ),
                ),
                
                // Clear Button
                if (_searchController.text.isNotEmpty || _hasActiveFilters)
                  IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear_rounded),
                  ),
              ],
            ),
          ),
          
          // Expanded Filters
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Tags Filter
                  if (widget.availableTags.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Filter by Tags',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                            _performSearch();
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                  
                  // Date Range Filter
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Date Range',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.calendar_today_rounded),
                          label: Text(
                            _selectedDateRange == null
                              ? 'Select date range'
                              : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                          ),
                        ),
                      ),
                      
                      if (_selectedDateRange != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                            _performSearch();
                          },
                          icon: const Icon(Icons.close_rounded),
                          iconSize: 20,
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quick Date Filters
                  Wrap(
                    spacing: 8,
                    children: [
                      _QuickDateChip(
                        label: 'Today',
                        onTap: () => _setQuickDateRange(0),
                      ),
                      _QuickDateChip(
                        label: 'This Week',
                        onTap: () => _setQuickDateRange(7),
                      ),
                      _QuickDateChip(
                        label: 'This Month',
                        onTap: () => _setQuickDateRange(30),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setQuickDateRange(int days) {
    final now = DateTime.now();
    final start = days == 0 
      ? DateTime(now.year, now.month, now.day)
      : now.subtract(Duration(days: days));
    
    setState(() {
      _selectedDateRange = DateTimeRange(
        start: start,
        end: now,
      );
    });
    _performSearch();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: onTap,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }
}
