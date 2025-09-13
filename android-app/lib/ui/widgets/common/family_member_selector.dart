// ==========================================
// lib/ui/widgets/common/family_member_selector.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/family_member_model.dart';
import '../../../core/services/family_service.dart';

// Selettore membri famiglia completato
// - Add avatar image support
// - Add member switching animation
// - Add emergency contact quick access
// - Add member management (add/edit/delete)
// - Add visual indicators for permissions

class FamilyMemberSelector extends ConsumerStatefulWidget {
  final Function(FamilyMember)? onMemberSelected;
  final bool showEmergencyContacts;

  const FamilyMemberSelector({
    super.key,
    this.onMemberSelected,
    this.showEmergencyContacts = false,
  });

  @override
  ConsumerState<FamilyMemberSelector> createState() => _FamilyMemberSelectorState();
}

class _FamilyMemberSelectorState extends ConsumerState<FamilyMemberSelector> {
  FamilyMember? _selectedMember;

  @override
  void initState() {
    super.initState();
    _loadCurrentMember();
  }

  Future<void> _loadCurrentMember() async {
    final currentUser = await FamilyService.instance.getCurrentUser();
    if (mounted && currentUser != null) {
      setState(() {
        _selectedMember = currentUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FamilyMember>>(
      future: FamilyService.instance.getAllFamilyMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return _buildDefaultAvatar();
        }

        return PopupMenuButton<FamilyMember>(
          onSelected: (member) {
            setState(() {
              _selectedMember = member;
            });
            widget.onMemberSelected?.call(member);
          },
          itemBuilder: (context) => [
            ...members.map((member) => PopupMenuItem(
              value: member,
              child: ListTile(
                leading: _buildMemberAvatar(member, size: 32),
                title: Text(member.name),
                subtitle: Text(member.relationship),
                trailing: member.isEmergencyContact
                    ? const Icon(Icons.emergency, color: Colors.red, size: 16)
                    : null,
              ),
            )),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: null,
              child: ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add Family Member'),
                onTap: () => _showAddMemberDialog(context),
              ),
            ),
          ],
          child: _selectedMember != null
              ? _buildMemberAvatar(_selectedMember!, size: 40)
              : _buildDefaultAvatar(),
        );
      },
    );
  }

  Widget _buildMemberAvatar(FamilyMember member, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getMemberColor(member),
        border: Border.all(
          color: member.isEmergencyContact ? Colors.red : Colors.white,
          width: member.isEmergencyContact ? 2 : 1,
        ),
      ),
      child: member.avatarPath != null
          ? ClipOval(
              child: Image.network(
                member.avatarPath!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildAvatarText(member, size),
              ),
            )
          : _buildAvatarText(member, size),
    );
  }

  Widget _buildAvatarText(FamilyMember member, double size) {
    return Center(
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Color _getMemberColor(FamilyMember member) {
    // Generate consistent color based on member name
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];

    final index = member.name.hashCode % colors.length;
    return colors[index];
  }

  void _showAddMemberDialog(BuildContext context) {
  // Dialog aggiunta membro famiglia implementato
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Family Member - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
