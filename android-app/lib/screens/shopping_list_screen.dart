import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';
import '../providers/shopping_providers.dart';
import '../services/shopping_collaboration_service.dart';
import '../widgets/collaboration_widgets.dart';
import 'family_sharing_screen.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDemoData();
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
    super.dispose();
  }

  void _loadDemoData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(shoppingListsProvider.notifier);
      
      final demoList1 = ShoppingList(
        id: 'demo1',
        name: 'Spesa Settimanale',
        description: 'Lista della spesa per questa settimana',
        category: ShoppingListCategory.groceries,
        items: [
          ShoppingItem(
            id: 'item1',
            name: 'Latte',
            quantity: 2,
            unit: 'litri',
            category: ShoppingCategory.groceries,
            estimatedPrice: 2.50,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
          ShoppingItem(
            id: 'item2',
            name: 'Pane',
            quantity: 1,
            unit: 'kg',
            category: ShoppingCategory.groceries,
            estimatedPrice: 1.20,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
          ShoppingItem(
            id: 'item3',
            name: 'Detersivo',
            quantity: 1,
            unit: 'bottiglia',
            category: ShoppingCategory.household,
            estimatedPrice: 3.50,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
          ShoppingItem(
            id: 'item4',
            name: 'Shampoo',
            quantity: 1,
            unit: 'bottiglia',
            category: ShoppingCategory.personal,
            estimatedPrice: 4.90,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
          ShoppingItem(
            id: 'item5',
            name: 'Smartphone Case',
            quantity: 1,
            category: ShoppingCategory.electronics,
            estimatedPrice: 15.00,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
        ],
        createdAt: DateTime.now(),
        createdBy: 'user1',
        sharedWith: ['family1'],
      );
      
      final demoList2 = ShoppingList(
        id: 'demo2',
        name: 'Abbigliamento Inverno',
        description: 'Vestiti per la stagione invernale',
        category: ShoppingListCategory.clothing,
        items: [
          ShoppingItem(
            id: 'item6',
            name: 'Maglione',
            quantity: 1,
            category: ShoppingCategory.clothing,
            estimatedPrice: 35.00,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
          ShoppingItem(
            id: 'item7',
            name: 'Sciarpa',
            quantity: 1,
            category: ShoppingCategory.clothing,
            estimatedPrice: 12.00,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
        ],
        createdAt: DateTime.now(),
        createdBy: 'user1',
      );
      
      final demoList3 = ShoppingList(
        id: 'demo3',
        name: 'Farmacia',
        description: 'Prodotti per la salute',
        category: ShoppingListCategory.health,
        items: [
          ShoppingItem(
            id: 'item8',
            name: 'Vitamina C',
            quantity: 1,
            unit: 'confezione',
            category: ShoppingCategory.health,
            estimatedPrice: 8.50,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
          ShoppingItem(
            id: 'item9',
            name: 'Cerotti',
            quantity: 1,
            unit: 'scatola',
            category: ShoppingCategory.health,
            estimatedPrice: 3.20,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
          ShoppingItem(
            id: 'item10',
            name: 'Termometro',
            quantity: 1,
            category: ShoppingCategory.electronics,
            estimatedPrice: 12.00,
            createdAt: DateTime.now(),
            createdBy: 'user1',
          ),
        ],
        createdAt: DateTime.now(),
        createdBy: 'user1',
      );
      
      notifier.addList(demoList1);
      notifier.addList(demoList2);
      notifier.addList(demoList3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allLists = ref.watch(shoppingListsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste della Spesa'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
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
      body: ListView.builder(
        itemCount: allLists.length,
        itemBuilder: (context, index) {
          final list = allLists[index];
          return Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: Text(list.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${list.totalItems} elementi'),
                      if (list.sharedWith.isNotEmpty)
                        const SizedBox(height: 4),
                      if (list.sharedWith.isNotEmpty)
                        CollaborationIndicator(listId: list.id),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
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
                      const PopupMenuItem(value: 'share', child: Text('Condividi')),
                      const PopupMenuItem(value: 'duplicate', child: Text('Duplica')),
                      const PopupMenuItem(value: 'delete', child: Text('Elimina')),
                    ],
                  ),
                  onTap: () => _openList(list),
                ),
                if (list.sharedWith.isNotEmpty)
                  CollaborationFeed(listId: list.id),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creazione nuova lista')),
        ),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openList(ShoppingList list) async {
    // Simula apertura lista e inizio sessione collaborazione
    final service = ref.read(shoppingCollaborationServiceProvider);
    await service.joinListSession(list.id, 'current_user', 'Utente Corrente');
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Apertura: ${list.name}')),
    );
    
    // Demo: simula altri utenti che si uniscono
    if (list.sharedWith.isNotEmpty) {
      Future.delayed(const Duration(seconds: 2), () async {
        await service.joinListSession(list.id, 'family1', 'Mario Rossi');
      });
      
      Future.delayed(const Duration(seconds: 4), () async {
        await service.notifyItemAdded(
          list.id,
          ShoppingItem(
            id: 'demo_item_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Pane',
            quantity: 1,
            createdAt: DateTime.now(),
            createdBy: 'family1',
          ),
          'family1',
          'Mario Rossi',
        );
      });
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
