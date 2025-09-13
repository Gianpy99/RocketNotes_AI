import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';
import '../services/family_shopping_service.dart';

/// T092: Family Sharing Screen per Shopping Lists
class FamilySharingScreen extends ConsumerStatefulWidget {
  final ShoppingList shoppingList;

  const FamilySharingScreen({
    super.key,
    required this.shoppingList,
  });

  @override
  ConsumerState<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends ConsumerState<FamilySharingScreen> {
  final TextEditingController _emailController = TextEditingController();
  final Set<String> _selectedMembers = <String>{};
  SharePermission _selectedPermission = SharePermission.edit;

  @override
  void initState() {
    super.initState();
    // Inizializza con i membri già condivisi
    _selectedMembers.addAll(widget.shoppingList.sharedWith);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyMembersAsync = ref.watch(familyMembersProvider);
    final sharingState = ref.watch(sharingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Condividi Lista'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (sharingState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _selectedMembers.isNotEmpty ? _saveSharing : null,
              child: const Text(
                'Salva',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: familyMembersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(familyMembersProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
        data: (familyMembers) => _buildContent(familyMembers, sharingState),
      ),
    );
  }

  Widget _buildContent(List<FamilyMember> familyMembers, SharingState sharingState) {
    return Column(
      children: [
        // Info lista
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Colors.green[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.shoppingList.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.shoppingList.description != null)
                Text(
                  widget.shoppingList.description!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 8),
              Text(
                '${widget.shoppingList.totalItems} elementi • ${widget.shoppingList.pendingItems} da comprare',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Errore
                if (sharingState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sharingState.error!,
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Permessi
                const Text(
                  'Livello di accesso:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPermissionSelector(),
                const SizedBox(height: 24),

                // Membri famiglia
                const Text(
                  'Membri della famiglia:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFamilyMembersList(familyMembers),
                const SizedBox(height: 24),

                // Invita per email
                const Text(
                  'Invita nuovi membri:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildEmailInvite(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionSelector() {
    return Column(
      children: SharePermission.values.map((permission) {
        return RadioListTile<SharePermission>(
          title: Text(_getPermissionTitle(permission)),
          subtitle: Text(_getPermissionDescription(permission)),
          value: permission,
          groupValue: _selectedPermission,
          onChanged: (SharePermission? value) {
            if (value != null) {
              setState(() {
                _selectedPermission = value;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildFamilyMembersList(List<FamilyMember> familyMembers) {
    return Column(
      children: familyMembers.map((member) {
        final isSelected = _selectedMembers.contains(member.id);
        final isAlreadyShared = widget.shoppingList.sharedWith.contains(member.id);

        return Card(
          child: CheckboxListTile(
            title: Text(member.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email),
                if (isAlreadyShared)
                  const Text(
                    'Già condivisa',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            secondary: CircleAvatar(
              backgroundColor: _getRoleColor(member.role),
              child: Text(member.avatar),
            ),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedMembers.add(member.id);
                } else {
                  _selectedMembers.remove(member.id);
                }
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmailInvite() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'esempio@email.com',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _inviteByEmail,
            icon: const Icon(Icons.send),
            label: const Text('Invia Invito'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'L\'invitato riceverà un\'email con il link per accedere alla lista',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getPermissionTitle(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'Solo visualizzazione';
      case SharePermission.edit:
        return 'Modifica elementi';
      case SharePermission.manage:
        return 'Gestione completa';
    }
  }

  String _getPermissionDescription(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'Può vedere la lista ma non modificarla';
      case SharePermission.edit:
        return 'Può aggiungere, modificare e completare elementi';
      case SharePermission.manage:
        return 'Può fare tutto, incluso condividere con altri';
    }
  }

  Color _getRoleColor(FamilyRole role) {
    switch (role) {
      case FamilyRole.parent:
        return Colors.blue[100]!;
      case FamilyRole.child:
        return Colors.green[100]!;
      case FamilyRole.guest:
        return Colors.orange[100]!;
    }
  }

  void _saveSharing() async {
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno un membro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await ref.read(sharingStateProvider.notifier).shareList(
      widget.shoppingList.id,
      _selectedMembers.toList(),
      _selectedPermission,
    );

    final state = ref.read(sharingStateProvider);
    if (state.error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista condivisa con successo!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Indica successo
    }
  }

  void _inviteByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un indirizzo email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un indirizzo email valido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await ref.read(sharingStateProvider.notifier).inviteMember(
      email,
      widget.shoppingList.id,
    );

    final state = ref.read(sharingStateProvider);
    if (state.error == null && mounted) {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invito inviato a $email'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}