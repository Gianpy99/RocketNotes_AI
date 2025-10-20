import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';
import '../providers/shopping_providers.dart';
import '../services/shopping_collaboration_service.dart';
import '../widgets/collaboration_widgets.dart';
import 'family_sharing_screen.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newListNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeCollaboration();
  }

  void _initializeCollaboration() async {
    final service = ref.read(shoppingCollaborationServiceProvider);
    await service.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _newListNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allLists = ref.watch(shoppingListsProvider);
    final activeLists = allLists.where((list) => !list.isCompleted).toList();
    final completedLists = allLists.where((list) => list.isCompleted).toList();
    final sharedLists = allLists.where((list) => list.sharedWith.isNotEmpty).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste della Spesa'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: 'Attive (${activeLists.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Completate (${completedLists.length})',
            ),
            Tab(
              icon: const Icon(Icons.people),
              text: 'Condivise (${sharedLists.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Categorie',
            onPressed: () => Navigator.of(context).pushNamed('/shopping/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Template',
            onPressed: () => Navigator.of(context).pushNamed('/shopping/templates'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(activeLists, empty: 'Nessuna lista attiva'),
          _buildListView(completedLists, empty: 'Nessuna lista completata'),
          _buildListView(sharedLists, empty: 'Nessuna lista condivisa'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateListDialog,
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add),
        label: const Text('Nuova Lista'),
      ),
    );
  }

  Widget _buildListView(List<ShoppingList> lists, {required String empty}) {
    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              empty,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: lists.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final list = lists[index];
        final pendingCount = list.items.where((i) => i.status == ShoppingItemStatus.pending).length;
        final completedCount = list.items.where((i) => i.status == ShoppingItemStatus.purchased).length;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: InkWell(
            onTap: () => _openListDetail(list),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(list.category),
                          color: Colors.green[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              list.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (list.description != null && list.description!.isNotEmpty)
                              Text(
                                list.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'open':
                              _openListDetail(list);
                              break;
                            case 'share':
                              _shareList(list);
                              break;
                            case 'duplicate':
                              _duplicateList(list);
                              break;
                            case 'delete':
                              _deleteList(list);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new),
                                SizedBox(width: 8),
                                Text('Apri'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share),
                                SizedBox(width: 8),
                                Text('Condividi'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy),
                                SizedBox(width: 8),
                                Text('Duplica'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Elimina', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatChip(Icons.shopping_bag, '$pendingCount da comprare', Colors.orange),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.check, '$completedCount acquistati', Colors.green),
                      if (list.sharedWith.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildStatChip(Icons.people, '${list.sharedWith.length}', Colors.blue),
                      ],
                    ],
                  ),
                  if (list.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: list.completionPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                    ),
                  ],
                  if (list.sharedWith.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    CollaborationIndicator(listId: list.id),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newListNameController,
              decoration: const InputDecoration(
                labelText: 'Nome lista *',
                hintText: 'Es: Spesa settimanale',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oppure crea da template:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._getTemplateButtons(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newListNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _newListNameController.text.trim();
              if (name.isEmpty) return;

              final newList = ShoppingList(
                id: 'list_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                description: 'Creata il ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                category: ShoppingListCategory.groceries,
                items: [],
                createdAt: DateTime.now(),
                createdBy: 'current_user',
                sharedWith: [],
              );

              ref.read(shoppingListsProvider.notifier).addList(newList);
              _newListNameController.clear();
              Navigator.pop(context);

              // Open the new list
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingListDetailScreen(listId: newList.id),
                ),
              );
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }

  List<Widget> _getTemplateButtons() {
    final templates = ref.watch(shoppingTemplatesProvider);

    return templates.take(3).map((template) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: OutlinedButton(
          onPressed: () {
            final newList = ref.read(shoppingTemplatesProvider.notifier).createListFromTemplate(
                  template.id,
                  'current_user',
                );
            ref.read(shoppingListsProvider.notifier).addList(newList);

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lista "${newList.name}" creata con ${newList.items.length} prodotti')),
            );

            // Open the new list
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShoppingListDetailScreen(listId: newList.id),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  template.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Chip(
                label: Text(
                  '${template.defaultItems.length}',
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _openListDetail(ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListDetailScreen(listId: list.id),
      ),
    );
  }

  IconData _getCategoryIcon(ShoppingListCategory category) {
    switch (category) {
      case ShoppingListCategory.groceries:
        return Icons.shopping_basket;
      case ShoppingListCategory.household:
        return Icons.home;
      case ShoppingListCategory.personal:
        return Icons.person;
      case ShoppingListCategory.electronics:
        return Icons.devices;
      case ShoppingListCategory.clothing:
        return Icons.checkroom;
      case ShoppingListCategory.health:
        return Icons.local_hospital;
      case ShoppingListCategory.other:
        return Icons.category;
    }
  }

  void _shareList(ShoppingList list) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FamilySharingScreen(shoppingList: list),
      ),
    );
    
    if (result == true) {
      // Lista condivisa con successo
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista condivisa con successo!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _duplicateList(ShoppingList list) {
    final duplicated = list.copyWith(
      id: 'dup_${DateTime.now().millisecondsSinceEpoch}',
      name: '${list.name} (Copia)',
      createdAt: DateTime.now(),
    );
    ref.read(shoppingListsProvider.notifier).addList(duplicated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lista "${duplicated.name}" creata')),
    );
  }

  void _deleteList(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Lista'),
        content: Text('Elimina "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shoppingListsProvider.notifier).deleteList(list.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lista "${list.name}" eliminata')),
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
