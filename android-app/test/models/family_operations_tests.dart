import 'package:flutter_test/flutter_test.dart';
import 'package:pensieve/models/family.dart';
import 'package:pensieve/models/family_member.dart';
import 'package:pensieve/models/family_invitation.dart';

void main() {
  group('Family Model Unit Tests', () {
    group('Family Creation and Validation', () {
      test('Family should serialize to JSON correctly', () {
        final settings = FamilySettings(
          allowPublicSharing: true,
          requireApprovalForSharing: false,
          maxMembers: 10,
          defaultNoteExpiration: const Duration(days: 30),
          enableRealTimeSync: true,
          notifications: NotificationPreferences(
            emailInvitations: true,
            pushNotifications: true,
            activityDigest: ActivityDigestFrequency.weekly,
          ),
        );

        final family = Family(
          id: 'family-id',
          name: 'Test Family',
          adminUserId: 'admin-id',
          createdAt: DateTime.now(),
          memberIds: ['admin-id'],
          settings: settings,
          updatedAt: DateTime.now(),
        );

        final json = family.toJson();
        expect(json['name'], equals('Test Family'));
        expect(json['adminUserId'], equals('admin-id'));
        expect(json['memberIds'], isA<List>());
        expect(json['createdAt'], isNotNull);
        expect(json['updatedAt'], isNotNull);
      });

      test('Family should deserialize from JSON correctly', () {
        final json = {
          'id': 'family-id',
          'name': 'Test Family',
          'adminUserId': 'admin-id',
          'memberIds': ['admin-id'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'settings': {
            'allowPublicSharing': true,
            'requireApprovalForSharing': false,
            'maxMembers': 10,
            'defaultNoteExpiration': 'P30D',
            'enableRealTimeSync': true,
            'notifications': {
              'emailInvitations': true,
              'pushNotifications': true,
              'activityDigest': 'weekly',
            },
          },
        };

        final family = Family.fromJson(json);
        expect(family.id, equals('family-id'));
        expect(family.name, equals('Test Family'));
        expect(family.adminUserId, equals('admin-id'));
        expect(family.memberIds, contains('admin-id'));
      });

      test('Family copyWith should work correctly', () {
        final original = Family(
          id: 'family-id',
          name: 'Original Name',
          adminUserId: 'admin-id',
          createdAt: DateTime.now(),
          memberIds: ['admin-id'],
          settings: _createDefaultSettings(),
          updatedAt: DateTime.now(),
        );

        final updated = original.copyWith(name: 'Updated Name');

        expect(updated.name, equals('Updated Name'));
        expect(updated.adminUserId, equals(original.adminUserId));
        expect(updated.id, equals(original.id));
      });
    });

    group('Family Member Model Tests', () {
      test('FamilyMember should create owner correctly', () {
        final owner = FamilyMember.createOwner(
          userId: 'owner-id',
          familyId: 'family-id',
        );

        expect(owner.userId, equals('owner-id'));
        expect(owner.familyId, equals('family-id'));
        expect(owner.role, equals(FamilyRole.owner));
        expect(owner.isOwner, isTrue);
        expect(owner.isAdmin, isTrue);
        expect(owner.canInvite, isTrue);
        expect(owner.canManage, isTrue);
      });

      test('FamilyMember should create with role correctly', () {
        final editor = FamilyMember.createWithRole(
          userId: 'editor-id',
          familyId: 'family-id',
          role: FamilyRole.editor,
        );

        expect(editor.userId, equals('editor-id'));
        expect(editor.role, equals(FamilyRole.editor));
        expect(editor.isOwner, isFalse);
        expect(editor.canEdit, isTrue);
        expect(editor.canInvite, isFalse);
        expect(editor.canManage, isFalse);
      });

      test('FamilyMember copyWith should work correctly', () {
        final original = FamilyMember.createWithRole(
          userId: 'user-id',
          familyId: 'family-id',
          role: FamilyRole.viewer,
        );

        final updated = original.copyWith(role: FamilyRole.editor);

        expect(updated.role, equals(FamilyRole.editor));
        expect(updated.userId, equals(original.userId));
        expect(updated.familyId, equals(original.familyId));
      });

      test('FamilyMember should serialize/deserialize correctly', () {
        final member = FamilyMember.createWithRole(
          userId: 'user-id',
          familyId: 'family-id',
          role: FamilyRole.editor,
        );

        final json = member.toJson();
        expect(json['userId'], equals('user-id'));
        expect(json['familyId'], equals('family-id'));
        expect(json['role'], equals('editor'));
        expect(json['permissions'], isNotNull);
      });
    });

    group('Member Permissions Tests', () {
      test('Owner permissions should have all capabilities', () {
        final ownerPerms = MemberPermissions.owner();

        expect(ownerPerms.canInviteMembers, isTrue);
        expect(ownerPerms.canRemoveMembers, isTrue);
        expect(ownerPerms.canEditSharedNotes, isTrue);
        expect(ownerPerms.canDeleteSharedNotes, isTrue);
        expect(ownerPerms.canManagePermissions, isTrue);
        expect(ownerPerms.hasAdminCapabilities, isTrue);
        expect(ownerPerms.canModifyContent, isTrue);
        expect(ownerPerms.canShareContent, isTrue);
      });

      test('Editor permissions should have content capabilities', () {
        final editorPerms = MemberPermissions.editor();

        expect(editorPerms.canInviteMembers, isFalse);
        expect(editorPerms.canRemoveMembers, isFalse);
        expect(editorPerms.canEditSharedNotes, isTrue);
        expect(editorPerms.canDeleteSharedNotes, isFalse);
        expect(editorPerms.canManagePermissions, isFalse);
        expect(editorPerms.hasAdminCapabilities, isFalse);
        expect(editorPerms.canModifyContent, isTrue);
        expect(editorPerms.canShareContent, isTrue);
      });

      test('Viewer permissions should have read-only capabilities', () {
        final viewerPerms = MemberPermissions.viewer();

        expect(viewerPerms.canInviteMembers, isFalse);
        expect(viewerPerms.canRemoveMembers, isFalse);
        expect(viewerPerms.canEditSharedNotes, isFalse);
        expect(viewerPerms.canDeleteSharedNotes, isFalse);
        expect(viewerPerms.canManagePermissions, isFalse);
        expect(viewerPerms.hasAdminCapabilities, isFalse);
        expect(viewerPerms.canModifyContent, isFalse);
        expect(viewerPerms.canShareContent, isFalse);
      });

      test('MemberPermissions copyWith should work correctly', () {
        final original = MemberPermissions.viewer();
        final modified = original.copyWith(canEditSharedNotes: true);

        expect(modified.canEditSharedNotes, isTrue);
        expect(modified.canShareNotes, equals(original.canShareNotes));
        expect(modified.canInviteMembers, equals(original.canInviteMembers));
      });

      test('MemberPermissions forRole should return correct permissions', () {
        expect(MemberPermissions.forRole(FamilyRole.owner).hasAdminCapabilities, isTrue);
        expect(MemberPermissions.forRole(FamilyRole.admin).hasAdminCapabilities, isTrue);
        expect(MemberPermissions.forRole(FamilyRole.editor).canModifyContent, isTrue);
        expect(MemberPermissions.forRole(FamilyRole.viewer).canModifyContent, isFalse);
        expect(MemberPermissions.forRole(FamilyRole.limited).canShareContent, isFalse);
      });
    });

    group('Family Settings Tests', () {
      test('FamilySettings should serialize/deserialize correctly', () {
        final settings = FamilySettings(
          allowPublicSharing: true,
          requireApprovalForSharing: false,
          maxMembers: 10,
          defaultNoteExpiration: const Duration(days: 30),
          enableRealTimeSync: true,
          notifications: NotificationPreferences(
            emailInvitations: true,
            pushNotifications: true,
            activityDigest: ActivityDigestFrequency.weekly,
          ),
        );

        final json = settings.toJson();
        expect(json['allowPublicSharing'], isTrue);
        expect(json['maxMembers'], equals(10));
        expect(json['notifications'], isNotNull);
      });

      test('FamilySettings copyWith should work correctly', () {
        final original = _createDefaultSettings();
        final updated = original.copyWith(maxMembers: 20);

        expect(updated.maxMembers, equals(20));
        expect(updated.allowPublicSharing, equals(original.allowPublicSharing));
      });
    });

    group('Family Invitation Tests', () {
      test('FamilyInvitation should have correct initial state', () {
        final invitation = FamilyInvitation(
          id: 'invitation-id',
          familyId: 'family-id',
          invitedBy: 'inviter-id',
          email: 'invitee@example.com',
          role: FamilyRole.editor,
          permissions: MemberPermissions.editor(),
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(invitation.id, equals('invitation-id'));
        expect(invitation.email, equals('invitee@example.com'));
        expect(invitation.status, equals(InvitationStatus.pending));
        expect(invitation.isExpired, isFalse);
      });

      test('FamilyInvitation should detect expiration correctly', () {
        final expiredInvitation = FamilyInvitation(
          id: 'invitation-id',
          familyId: 'family-id',
          invitedBy: 'inviter-id',
          email: 'invitee@example.com',
          role: FamilyRole.editor,
          permissions: MemberPermissions.editor(),
          status: InvitationStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(expiredInvitation.isExpired, isTrue);
      });

      test('FamilyInvitation should serialize/deserialize correctly', () {
        final invitation = FamilyInvitation(
          id: 'invitation-id',
          familyId: 'family-id',
          invitedBy: 'inviter-id',
          email: 'invitee@example.com',
          role: FamilyRole.editor,
          permissions: MemberPermissions.editor(),
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final json = invitation.toJson();
        expect(json['id'], equals('invitation-id'));
        expect(json['email'], equals('invitee@example.com'));
        expect(json['status'], equals('pending'));
        expect(json['permissions'], isNotNull);
      });
    });

    group('Role Hierarchy Tests', () {
      test('FamilyRole should have correct hierarchy', () {
        final roles = [
          FamilyRole.owner,
          FamilyRole.admin,
          FamilyRole.editor,
          FamilyRole.viewer,
          FamilyRole.limited,
        ];

        for (int i = 0; i < roles.length - 1; i++) {
          expect(roles[i].index < roles[i + 1].index, isTrue,
              reason: '${roles[i]} should have lower index than ${roles[i + 1]}');
        }
      });

      test('Role display names should be correct', () {
        expect(FamilyRole.owner.toString(), contains('owner'));
        expect(FamilyRole.admin.toString(), contains('admin'));
        expect(FamilyRole.editor.toString(), contains('editor'));
        expect(FamilyRole.viewer.toString(), contains('viewer'));
        expect(FamilyRole.limited.toString(), contains('limited'));
      });
    });

    group('Activity Digest Frequency Tests', () {
      test('ActivityDigestFrequency should have correct values', () {
        expect(ActivityDigestFrequency.never.toString(), contains('never'));
        expect(ActivityDigestFrequency.daily.toString(), contains('daily'));
        expect(ActivityDigestFrequency.weekly.toString(), contains('weekly'));
      });
    });

    group('Invitation Status Tests', () {
      test('InvitationStatus should have correct values', () {
        expect(InvitationStatus.pending.toString(), contains('pending'));
        expect(InvitationStatus.accepted.toString(), contains('accepted'));
        expect(InvitationStatus.rejected.toString(), contains('rejected'));
        expect(InvitationStatus.cancelled.toString(), contains('cancelled'));
        expect(InvitationStatus.expired.toString(), contains('expired'));
      });
    });
  });
}

// Helper function to create default settings for tests
FamilySettings _createDefaultSettings() {
  return FamilySettings(
    allowPublicSharing: true,
    requireApprovalForSharing: false,
    maxMembers: 10,
    defaultNoteExpiration: const Duration(days: 30),
    enableRealTimeSync: true,
    notifications: NotificationPreferences(
      emailInvitations: true,
      pushNotifications: true,
      activityDigest: ActivityDigestFrequency.weekly,
    ),
  );
}
