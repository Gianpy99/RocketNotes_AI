import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';
import '../providers/shopping_providers.dart';

/// T094: Shopping List Templates Screen
class ShoppingTemplatesScreen extends ConsumerStatefulWidget {
  const ShoppingTemplatesScreen({super.key});

  @override
  ConsumerState<ShoppingTemplatesScreen> createState() => _ShoppingTemplatesScreenState();
}

class _ShoppingTemplatesScreenState extends ConsumerState<ShoppingTemplatesScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(shoppingTemplatesProvider);
    final publicTemplates = templates.where((t) => t.isPublic).toList();
    final privateTemplates = templates.where((t) => !t.isPublic).toList();
    final recentTemplates = templates.where((t) => t.lastUsed != null).toList()
      ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
    final favoriteTemplates = templates.where((t) => t.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Liste'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createCustomTemplate,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Pubblici (${publicTemplates.length})'),
            Tab(text: 'Personali (${privateTemplates.length})'),
            Tab(text: 'Recenti (${recentTemplates.length})'),
            Tab(text: 'Preferiti (${favoriteTemplates.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplateList(publicTemplates, 'Nessun template pubblico'),
          _buildTemplateList(privateTemplates, 'Nessun template personale'),
          _buildTemplateList(recentTemplates, 'Nessun template recente'),
          _buildTemplateList(favoriteTemplates, 'Nessun template preferito'),
        ],
      ),
    );
  }

  Widget _buildTemplateList(List<ShoppingListTemplate> templates, String emptyMessage) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            if (emptyMessage.contains('personale'))
              TextButton.icon(
                onPressed: _createCustomTemplate,
                icon: const Icon(Icons.add),
                label: const Text('Crea il tuo primo template'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ExpansionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCategoryColor(template.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _getCategoryColor(template.category)),
              ),
              child: Icon(
                _getCategoryIcon(template.category),
                color: _getCategoryColor(template.category),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(template.name)),
                if (template.isFavorite)
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                if (template.isPopular)
                  const Icon(Icons.trending_up, color: Colors.orange, size: 16),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.description != null) Text(template.description!),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${template.defaultItems.length} elementi',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (template.lastUsed != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Usato ${_formatLastUsed(template.lastUsed!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                    if (template.usageCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${template.usageCount} volte',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleTemplateAction(value, template),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'use', child: Text('Usa Template')),
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(template.isFavorite ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti'),
                ),
                if (!template.isPublic) ...[
                  const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                  const PopupMenuItem(value: 'share', child: Text('Condividi')),
                ],
                const PopupMenuItem(value: 'duplicate', child: Text('Duplica')),
                if (!template.isPublic)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Elimina', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elementi del template:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: template.defaultItems.map((item) => Chip(
                        label: Text(item),
                        backgroundColor: Colors.green[50],
                        side: BorderSide(color: Colors.green[200]!),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _useTemplate(template),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Usa Template'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _previewTemplate(template),
                          icon: const Icon(Icons.preview),
                          label: const Text('Anteprima'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getCategoryColor(ShoppingListCategory category) {
    switch (category) {
      case ShoppingListCategory.groceries: return Colors.green;
      case ShoppingListCategory.household: return Colors.blue;
      case ShoppingListCategory.personal: return Colors.purple;
      case ShoppingListCategory.electronics: return Colors.orange;
      case ShoppingListCategory.clothing: return Colors.pink;
      case ShoppingListCategory.health: return Colors.red;
      case ShoppingListCategory.other: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ShoppingListCategory category) {
    switch (category) {
      case ShoppingListCategory.groceries: return Icons.shopping_cart;
      case ShoppingListCategory.household: return Icons.home;
      case ShoppingListCategory.personal: return Icons.person;
      case ShoppingListCategory.electronics: return Icons.electrical_services;
      case ShoppingListCategory.clothing: return Icons.checkroom;
      case ShoppingListCategory.health: return Icons.health_and_safety;
      case ShoppingListCategory.other: return Icons.category;
    }
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final diff = now.difference(lastUsed);
    
    if (diff.inDays == 0) {
      return 'oggi';
    } else if (diff.inDays == 1) {
      return 'ieri';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} giorni fa';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} settimane fa';
    } else {
      return '${(diff.inDays / 30).floor()} mesi fa';
    }
  }

  void _handleTemplateAction(String action, ShoppingListTemplate template) {
    switch (action) {
      case 'use':
        _useTemplate(template);
        break;
      case 'favorite':
        _toggleFavorite(template);
        break;
      case 'edit':
        _editTemplate(template);
        break;
      case 'share':
        _shareTemplate(template);
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }

  void _useTemplate(ShoppingListTemplate template) {
    final newList = ShoppingList(
      id: 'list_${DateTime.now().millisecondsSinceEpoch}',
      name: template.name,
      description: 'Creata da template: ${template.name}',
      category: template.category,
      items: template.defaultItems.map((itemName) => ShoppingItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}_${itemName.hashCode}',
        name: itemName,
        quantity: 1,
        createdAt: DateTime.now(),
        createdBy: 'current_user',
      )).toList(),
      createdAt: DateTime.now(),
      createdBy: 'current_user',
    );

    ref.read(shoppingListsProvider.notifier).addList(newList);
    ref.read(shoppingTemplatesProvider.notifier).markAsUsed(template.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lista "${newList.name}" creata dal template!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Visualizza',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _previewTemplate(ShoppingListTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anteprima: ${template.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (template.description != null) ...[
                Text(template.description!),
                const SizedBox(height: 16),
              ],
              const Text('Elementi inclusi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: template.defaultItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.shopping_cart_outlined),
                      title: Text(template.defaultItems[index]),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _useTemplate(template);
            },
            child: const Text('Usa Template'),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(ShoppingListTemplate template) {
    ref.read(shoppingTemplatesProvider.notifier).toggleFavorite(template.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          template.isFavorite 
            ? 'Rimosso dai preferiti' 
            : 'Aggiunto ai preferiti',
        ),
      ),
    );
  }

  void _editTemplate(ShoppingListTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modifica template - funzionalità in sviluppo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _shareTemplate(ShoppingListTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Condivisione template - funzionalità in sviluppo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _duplicateTemplate(ShoppingListTemplate template) {
    final duplicated = template.copyWith(
      id: 'template_${DateTime.now().millisecondsSinceEpoch}',
      name: '${template.name} (Copia)',
      isPublic: false,
      createdAt: DateTime.now(),
      createdBy: 'current_user',
    );

    ref.read(shoppingTemplatesProvider.notifier).addTemplate(duplicated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template "${duplicated.name}" duplicato')),
    );
  }

  void _deleteTemplate(ShoppingListTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Template'),
        content: Text('Eliminare il template "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shoppingTemplatesProvider.notifier).deleteTemplate(template.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Template "${template.name}" eliminato')),
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _createCustomTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creazione template personalizzato - funzionalità in sviluppo'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}