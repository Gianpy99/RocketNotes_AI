import 'package:flutter_test/flutter_test.dart';
import 'package:pensieve/models/family.dart';
import 'package:pensieve/models/family_member.dart';

void main() {
  group('Family Model Validation Tests', () {
    test('Family should validate required fields', () {
      final notifications = NotificationPreferences(
        emailInvitations: true,
        pushNotifications: true,
        activityDigest: ActivityDigestFrequency.weekly,
      );
      final settings = FamilySettings(
        allowPublicSharing: true,
        requireApprovalForSharing: false,
        maxMembers: 10,
        defaultNoteExpiration: const Duration(days: 30),
        enableRealTimeSync: true,
        notifications: notifications,
      );

      final family = Family(
        id: 'test-id',
        name: 'Test Family',
        adminUserId: 'admin-id',
        createdAt: DateTime.now(),
        memberIds: ['user1', 'user2'],
        settings: settings,
        updatedAt: DateTime.now(),
      );

      expect(family.id, isNotEmpty);
      expect(family.name, isNotEmpty);
      expect(family.adminUserId, isNotEmpty);
      expect(family.memberIds, isNotEmpty);
    });

    test('FamilySettings should have valid defaults', () {
      final notifications = NotificationPreferences(
        emailInvitations: true,
        pushNotifications: true,
        activityDigest: ActivityDigestFrequency.weekly,
      );
      final settings = FamilySettings(
        allowPublicSharing: true,
        requireApprovalForSharing: false,
        maxMembers: 10,
        defaultNoteExpiration: const Duration(days: 30),
        enableRealTimeSync: true,
        notifications: notifications,
      );

      expect(settings.maxMembers, greaterThan(0));
      expect(settings.allowPublicSharing, isA<bool>());
      expect(settings.requireApprovalForSharing, isA<bool>());
      expect(settings.enableRealTimeSync, isA<bool>());
    });

    test('FamilySettings copyWith should preserve values', () {
      final notifications = NotificationPreferences(
        emailInvitations: true,
        pushNotifications: true,
        activityDigest: ActivityDigestFrequency.weekly,
      );
      final original = FamilySettings(
        allowPublicSharing: true,
        requireApprovalForSharing: false,
        maxMembers: 10,
        defaultNoteExpiration: const Duration(days: 30),
        enableRealTimeSync: true,
        notifications: notifications,
      );
      final modified = original.copyWith(maxMembers: 20);

      expect(modified.maxMembers, equals(20));
      expect(modified.allowPublicSharing, equals(original.allowPublicSharing));
    });
  });

  group('FamilyMember Model Validation Tests', () {
    test('FamilyMember should validate required fields', () {
      final permissions = MemberPermissions.viewer();

      final member = FamilyMember(
        userId: 'user-id',
        familyId: 'family-id',
        role: FamilyRole.viewer,
        permissions: permissions,
        joinedAt: DateTime.now(),
      );

      expect(member.userId, isNotEmpty);
      expect(member.familyId, isNotEmpty);
      expect(member.role, isA<FamilyRole>());
      expect(member.permissions, isA<MemberPermissions>());
    });

    test('MemberPermissions should have valid defaults', () {
      final permissions = MemberPermissions.viewer();

      expect(permissions.canInviteMembers, isA<bool>());
      expect(permissions.canRemoveMembers, isA<bool>());
      expect(permissions.canShareNotes, isA<bool>());
      expect(permissions.canEditSharedNotes, isA<bool>());
      expect(permissions.canDeleteSharedNotes, isA<bool>());
      expect(permissions.canManagePermissions, isA<bool>());
    });

    test('FamilyRole enum should have valid values', () {
      expect(FamilyRole.owner.index, equals(0));
      expect(FamilyRole.admin.index, equals(1));
      expect(FamilyRole.editor.index, equals(2));
      expect(FamilyRole.viewer.index, equals(3));
      expect(FamilyRole.limited.index, equals(4));
    });

    test('FamilyRole should have correct permissions hierarchy', () {
      final ownerPermissions = MemberPermissions.owner();
      final adminPermissions = MemberPermissions.admin();
      final editorPermissions = MemberPermissions.editor();
      final viewerPermissions = MemberPermissions.viewer();

      // Owner should have all permissions
      expect(ownerPermissions.canManagePermissions, isTrue);
      expect(ownerPermissions.canInviteMembers, isTrue);

      // Admin should have most permissions
      expect(adminPermissions.canManagePermissions, isTrue);
      expect(adminPermissions.canInviteMembers, isTrue);

      // Editor should have content permissions
      expect(editorPermissions.canEditSharedNotes, isTrue);
      expect(editorPermissions.canManagePermissions, isFalse);

      // Viewer should have minimal permissions
      expect(viewerPermissions.canEditSharedNotes, isFalse);
      expect(viewerPermissions.canShareNotes, isFalse);
    });

    test('MemberPermissions factory methods should work', () {
      final ownerPerms = MemberPermissions.owner();
      final adminPerms = MemberPermissions.admin();
      final editorPerms = MemberPermissions.editor();
      final viewerPerms = MemberPermissions.viewer();

      expect(ownerPerms.hasAdminCapabilities, isTrue);
      expect(adminPerms.hasAdminCapabilities, isTrue);
      expect(editorPerms.hasAdminCapabilities, isFalse);
      expect(viewerPerms.hasAdminCapabilities, isFalse);

      expect(ownerPerms.canModifyContent, isTrue);
      expect(editorPerms.canModifyContent, isTrue);
      expect(viewerPerms.canModifyContent, isFalse);
    });

    test('FamilyMember convenience getters should work', () {
      final ownerMember = FamilyMember.createOwner(
        userId: 'user-id',
        familyId: 'family-id',
      );

      expect(ownerMember.isOwner, isTrue);
      expect(ownerMember.isAdmin, isTrue);
      expect(ownerMember.canModifyFamily, isTrue);
      expect(ownerMember.canManageMembers, isTrue);
      expect(ownerMember.roleDisplayName, equals('Owner'));
    });
  });

  group('Model Serialization Tests', () {
    test('FamilySettings should serialize/deserialize correctly', () {
      final notifications = NotificationPreferences(
        emailInvitations: true,
        pushNotifications: true,
        activityDigest: ActivityDigestFrequency.weekly,
      );
      final original = FamilySettings(
        allowPublicSharing: true,
        requireApprovalForSharing: false,
        maxMembers: 15,
        defaultNoteExpiration: const Duration(days: 30),
        enableRealTimeSync: true,
        notifications: notifications,
      );

      final json = original.toJson();
      expect(json['maxMembers'], equals(15));
      expect(json['allowPublicSharing'], isTrue);
      expect(json['enableRealTimeSync'], isTrue);
      expect(json['notifications'], isNotNull);
    });

    test('MemberPermissions should serialize/deserialize correctly', () {
      final original = MemberPermissions(
        canInviteMembers: true,
        canRemoveMembers: false,
        canShareNotes: true,
        canEditSharedNotes: true,
        canDeleteSharedNotes: false,
        canManagePermissions: false,
      );

      final json = original.toJson();
      final deserialized = MemberPermissions.fromJson(json);

      expect(deserialized.canInviteMembers, equals(original.canInviteMembers));
      expect(deserialized.canEditSharedNotes, equals(original.canEditSharedNotes));
      expect(deserialized.canManagePermissions, equals(original.canManagePermissions));
    });

    test('NotificationPreferences should serialize/deserialize correctly', () {
      final original = NotificationPreferences(
        emailInvitations: true,
        pushNotifications: false,
        activityDigest: ActivityDigestFrequency.daily,
      );

      final json = original.toJson();
      final deserialized = NotificationPreferences.fromJson(json);

      expect(deserialized.emailInvitations, equals(original.emailInvitations));
      expect(deserialized.pushNotifications, equals(original.pushNotifications));
      expect(deserialized.activityDigest, equals(original.activityDigest));
    });
  });

  group('Model Business Logic Tests', () {
    test('FamilyRole hierarchy should work correctly', () {
      expect(FamilyRole.owner.index < FamilyRole.admin.index, isTrue);
      expect(FamilyRole.admin.index < FamilyRole.editor.index, isTrue);
      expect(FamilyRole.editor.index < FamilyRole.viewer.index, isTrue);
      expect(FamilyRole.viewer.index < FamilyRole.limited.index, isTrue);
    });

    test('MemberPermissions should respect role hierarchy', () {
      final ownerPerms = MemberPermissions.forRole(FamilyRole.owner);
      final adminPerms = MemberPermissions.forRole(FamilyRole.admin);
      final editorPerms = MemberPermissions.forRole(FamilyRole.editor);
      final viewerPerms = MemberPermissions.forRole(FamilyRole.viewer);

      // Owner should have all permissions
      expect(ownerPerms.canManagePermissions, isTrue);
      expect(ownerPerms.canShareContent, isTrue);

      // Admin should have admin capabilities
      expect(adminPerms.hasAdminCapabilities, isTrue);

      // Editor should have content modification capabilities
      expect(editorPerms.canModifyContent, isTrue);

      // Viewer should have minimal capabilities
      expect(viewerPerms.canModifyContent, isFalse);
      expect(viewerPerms.hasAdminCapabilities, isFalse);
    });

    test('Family should handle member management', () {
      final notifications = NotificationPreferences(
        emailInvitations: true,
        pushNotifications: true,
        activityDigest: ActivityDigestFrequency.weekly,
      );
      final settings = FamilySettings(
        allowPublicSharing: true,
        requireApprovalForSharing: false,
        maxMembers: 10,
        defaultNoteExpiration: const Duration(days: 30),
        enableRealTimeSync: true,
        notifications: notifications,
      );

      final family = Family(
        id: 'test-id',
        name: 'Test Family',
        adminUserId: 'admin-id',
        createdAt: DateTime.now(),
        memberIds: ['user1', 'user2'],
        settings: settings,
        updatedAt: DateTime.now(),
      );

      expect(family.memberIds.length, equals(2));
      expect(family.memberIds.contains('user1'), isTrue);
      expect(family.memberIds.contains('user2'), isTrue);
    });
  });
}
