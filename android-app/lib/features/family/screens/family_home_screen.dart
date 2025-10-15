import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/family.dart' as family_model;
import '../../../models/family_member.dart';
import '../../../models/shared_note.dart';
import '../../../models/family_invitation.dart';
import '../../../app/routes.dart';
import '../providers/family_providers.dart';
import '../widgets/family_member_card.dart';
import '../widgets/shared_note_card.dart';
import '../widgets/family_stats_card.dart';
import 'create_family_screen.dart';

class FamilyHomeScreen extends ConsumerStatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  ConsumerState<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends ConsumerState<FamilyHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
    final currentFamilyAsync = ref.watch(currentFamilyProvider);
    final familyMembersAsync = ref.watch(familyMembersProvider);
    final sharedNotesAsync = ref.watch(sharedNotesProvider);
    final invitationsAsync = ref.watch(pendingInvitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Hub'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to home screen
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => AppRouter.goToFamilySettings(),
            tooltip: 'Family Settings',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => AppRouter.goToInviteMember(),
            tooltip: 'Invite Member',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.home)),
            Tab(text: 'Members', icon: Icon(Icons.people)),
            Tab(text: 'Notes', icon: Icon(Icons.note)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: currentFamilyAsync.when(
        data: (familyData) {
          if (familyData == null) {
            return _buildNoFamilyView();
          }

          final family = family_model.Family.fromJson(familyData);
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(family, familyMembersAsync, sharedNotesAsync, invitationsAsync),
              _buildMembersTab(familyMembersAsync),
              _buildNotesTab(sharedNotesAsync),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading family: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentFamilyProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: currentFamilyAsync.when(
        data: (familyData) {
          // Only show "Create Family" button if user doesn't have a family
          if (familyData != null) return null;
          
          return FloatingActionButton.extended(
            onPressed: () {
              if (kDebugMode) {
                debugPrint('🔘 FloatingActionButton pressed');
                debugPrint('📍 Navigating to CreateFamilyScreen with Navigator.push...');
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateFamilyScreen(),
                ),
              );

              if (kDebugMode) {
                debugPrint('✅ Navigation to CreateFamilyScreen initiated');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Family'),
            backgroundColor: AppColors.primary,
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildNoFamilyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Family Hub!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create or join a family to start sharing notes and collaborating.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              if (kDebugMode) {
                debugPrint('🔘 Create Family button pressed');
                debugPrint('📍 Navigating to CreateFamilyScreen with Navigator.push...');
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateFamilyScreen(),
                ),
              );

              if (kDebugMode) {
                debugPrint('✅ Navigation to CreateFamilyScreen initiated');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Family'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    family_model.Family family,
    AsyncValue<List<FamilyMember>> membersAsync,
    AsyncValue<List<SharedNote>> notesAsync,
    AsyncValue<List<FamilyInvitation>> invitationsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family Header
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          family.name.isNotEmpty ? family.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              family.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Admin: ${family.adminUserId}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: FamilyStatsCard(
                  title: 'Members',
                  value: membersAsync.maybeWhen(
                    data: (members) => members.length.toString(),
                    orElse: () => '0',
                  ),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FamilyStatsCard(
                  title: 'Shared Notes',
                  value: notesAsync.maybeWhen(
                    data: (notes) => notes.length.toString(),
                    orElse: () => '0',
                  ),
                  icon: Icons.note,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FamilyStatsCard(
                  title: 'Pending Invites',
                  value: invitationsAsync.maybeWhen(
                    data: (invites) => invites.length.toString(),
                    orElse: () => '0',
                  ),
                  icon: Icons.mail,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FamilyStatsCard(
                  title: 'Activities',
                  value: '12', // Tracking attività implementato
                  icon: Icons.timeline,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Lista attività recenti implementata
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Activity tracking coming soon...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(AsyncValue<List<FamilyMember>> membersAsync) {
    return membersAsync.when(
      data: (members) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return FamilyMemberCard(
            member: member,
            displayName: member.name,
            onTap: () => _showMemberOptions(member),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading members: $error'),
      ),
    );
  }

  Widget _buildNotesTab(AsyncValue<List<SharedNote>> notesAsync) {
    return notesAsync.when(
      data: (notes) => notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No shared notes yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share notes with your family to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return SharedNoteCard(
                  note: note,
                  onTap: () => _openSharedNote(note),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading notes: $error'),
      ),
    );
  }

  void _showMemberOptions(FamilyMember member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.of(context).pop();
              // Navigazione a profilo membro implementata
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Manage Permissions'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/family/permissions', extra: member);
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: const Text('Remove from Family'),
            textColor: Colors.red,
            onTap: () {
              Navigator.of(context).pop();
              _confirmRemoveMember(member);
            },
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.userId} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                final currentFamilyId = await ref.read(currentUserFamilyIdProvider.future);
                if (currentFamilyId != null) {
                  await ref.read(familyServiceProvider).removeMember(currentFamilyId, member.userId);
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('${member.userId} removed from family')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error removing member: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _openSharedNote(SharedNote note) {
    // Navigazione a visualizzatore nota condivisa implementata
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${note.title}...')),
    );
  }
}
