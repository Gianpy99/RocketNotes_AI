import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/family_member.dart';

void main() {
  group('Permission Logic Unit Tests', () {
    group('Role-Based Permissions', () {
      test('Owner role should have all permissions', () {
        final ownerPerms = MemberPermissions.forRole(FamilyRole.owner);

        expect(ownerPerms.canInviteMembers, isTrue);
        expect(ownerPerms.canRemoveMembers, isTrue);
        expect(ownerPerms.canShareNotes, isTrue);
        expect(ownerPerms.canEditSharedNotes, isTrue);
        expect(ownerPerms.canDeleteSharedNotes, isTrue);
        expect(ownerPerms.canManagePermissions, isTrue);
      });

      test('Admin role should have most permissions', () {
        final adminPerms = MemberPermissions.forRole(FamilyRole.admin);

        expect(adminPerms.canInviteMembers, isTrue);
        expect(adminPerms.canRemoveMembers, isTrue);
        expect(adminPerms.canShareNotes, isTrue);
        expect(adminPerms.canEditSharedNotes, isTrue);
        expect(adminPerms.canDeleteSharedNotes, isTrue);
        expect(adminPerms.canManagePermissions, isTrue);
      });

      test('Editor role should have content permissions', () {
        final editorPerms = MemberPermissions.forRole(FamilyRole.editor);

        expect(editorPerms.canInviteMembers, isFalse);
        expect(editorPerms.canRemoveMembers, isFalse);
        expect(editorPerms.canShareNotes, isTrue);
        expect(editorPerms.canEditSharedNotes, isTrue);
        expect(editorPerms.canDeleteSharedNotes, isFalse);
        expect(editorPerms.canManagePermissions, isFalse);
      });

      test('Viewer role should have read-only permissions', () {
        final viewerPerms = MemberPermissions.forRole(FamilyRole.viewer);

        expect(viewerPerms.canInviteMembers, isFalse);
        expect(viewerPerms.canRemoveMembers, isFalse);
        expect(viewerPerms.canShareNotes, isFalse);
        expect(viewerPerms.canEditSharedNotes, isFalse);
        expect(viewerPerms.canDeleteSharedNotes, isFalse);
        expect(viewerPerms.canManagePermissions, isFalse);
      });

      test('Limited role should have minimal permissions', () {
        final limitedPerms = MemberPermissions.forRole(FamilyRole.limited);

        expect(limitedPerms.canInviteMembers, isFalse);
        expect(limitedPerms.canRemoveMembers, isFalse);
        expect(limitedPerms.canShareNotes, isFalse);
        expect(limitedPerms.canEditSharedNotes, isFalse);
        expect(limitedPerms.canDeleteSharedNotes, isFalse);
        expect(limitedPerms.canManagePermissions, isFalse);
      });
    });

    group('Permission Capability Checks', () {
      test('hasAdminCapabilities should work correctly', () {
        final ownerPerms = MemberPermissions.owner();
        final adminPerms = MemberPermissions.admin();
        final editorPerms = MemberPermissions.editor();
        final viewerPerms = MemberPermissions.viewer();

        expect(ownerPerms.hasAdminCapabilities, isTrue);
        expect(adminPerms.hasAdminCapabilities, isTrue);
        expect(editorPerms.hasAdminCapabilities, isFalse);
        expect(viewerPerms.hasAdminCapabilities, isFalse);
      });

      test('canModifyContent should work correctly', () {
        final ownerPerms = MemberPermissions.owner();
        final editorPerms = MemberPermissions.editor();
        final viewerPerms = MemberPermissions.viewer();

        expect(ownerPerms.canModifyContent, isTrue);
        expect(editorPerms.canModifyContent, isTrue);
        expect(viewerPerms.canModifyContent, isFalse);
      });

      test('canShareContent should work correctly', () {
        final ownerPerms = MemberPermissions.owner();
        final editorPerms = MemberPermissions.editor();
        final viewerPerms = MemberPermissions.viewer();

        expect(ownerPerms.canShareContent, isTrue);
        expect(editorPerms.canShareContent, isTrue);
        expect(viewerPerms.canShareContent, isFalse);
      });
    });

    group('FamilyMember Permission Checks', () {
      test('Owner member should have all capabilities', () {
        final ownerMember = FamilyMember.createOwner(
          userId: 'user-id',
          familyId: 'family-id',
        );

        expect(ownerMember.isOwner, isTrue);
        expect(ownerMember.isAdmin, isTrue);
        expect(ownerMember.canModifyFamily, isTrue);
        expect(ownerMember.canManageMembers, isTrue);
        expect(ownerMember.canInvite, isTrue);
        expect(ownerMember.canRemove, isTrue);
        expect(ownerMember.canShare, isTrue);
        expect(ownerMember.canEdit, isTrue);
        expect(ownerMember.canDelete, isTrue);
        expect(ownerMember.canManage, isTrue);
      });

      test('Admin member should have admin capabilities', () {
        final adminMember = FamilyMember.createWithRole(
          userId: 'user-id',
          familyId: 'family-id',
          role: FamilyRole.admin,
        );

        expect(adminMember.isOwner, isFalse);
        expect(adminMember.isAdmin, isTrue);
        expect(adminMember.canModifyFamily, isTrue);
        expect(adminMember.canManageMembers, isTrue);
        expect(adminMember.canInvite, isTrue);
        expect(adminMember.canManage, isTrue);
      });

      test('Editor member should have content capabilities', () {
        final editorMember = FamilyMember.createWithRole(
          userId: 'user-id',
          familyId: 'family-id',
          role: FamilyRole.editor,
        );

        expect(editorMember.isOwner, isFalse);
        expect(editorMember.isAdmin, isFalse);
        expect(editorMember.canModifyFamily, isFalse);
        expect(editorMember.canManageMembers, isFalse);
        expect(editorMember.canInvite, isFalse);
        expect(editorMember.canShare, isTrue);
        expect(editorMember.canEdit, isTrue);
        expect(editorMember.canDelete, isFalse);
        expect(editorMember.canManage, isFalse);
      });

      test('Viewer member should have read-only capabilities', () {
        final viewerMember = FamilyMember.createWithRole(
          userId: 'user-id',
          familyId: 'family-id',
          role: FamilyRole.viewer,
        );

        expect(viewerMember.isOwner, isFalse);
        expect(viewerMember.isAdmin, isFalse);
        expect(viewerMember.canModifyFamily, isFalse);
        expect(viewerMember.canManageMembers, isFalse);
        expect(viewerMember.canInvite, isFalse);
        expect(viewerMember.canShare, isFalse);
        expect(viewerMember.canEdit, isFalse);
        expect(viewerMember.canDelete, isFalse);
        expect(viewerMember.canManage, isFalse);
      });
    });

    group('Permission Inheritance and Overrides', () {
      test('Custom permissions should override role defaults', () {
        final customPerms = MemberPermissions.viewer().copyWith(
          canInviteMembers: true, // Override to allow inviting
        );

        expect(customPerms.canInviteMembers, isTrue);
        expect(customPerms.canEditSharedNotes, isFalse); // Should keep original
        expect(customPerms.hasAdminCapabilities, isTrue); // Should be true due to invite permission
      });

      test('Permission copyWith should preserve other values', () {
        final original = MemberPermissions.editor();
        final modified = original.copyWith(canDeleteSharedNotes: true);

        expect(modified.canDeleteSharedNotes, isTrue);
        expect(modified.canEditSharedNotes, equals(original.canEditSharedNotes));
        expect(modified.canShareNotes, equals(original.canShareNotes));
        expect(modified.canInviteMembers, equals(original.canInviteMembers));
      });
    });

    group('Role Hierarchy Validation', () {
      test('Role hierarchy should be properly ordered', () {
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

      test('Higher roles should have more capabilities', () {
        final ownerPerms = MemberPermissions.forRole(FamilyRole.owner);
        final adminPerms = MemberPermissions.forRole(FamilyRole.admin);
        final editorPerms = MemberPermissions.forRole(FamilyRole.editor);
        final viewerPerms = MemberPermissions.forRole(FamilyRole.viewer);

        // Owner should have all capabilities that others have
        expect(ownerPerms.canManagePermissions, isTrue);
        expect(ownerPerms.canInviteMembers, isTrue);
        expect(ownerPerms.canEditSharedNotes, isTrue);

        // Admin should have admin capabilities
        expect(adminPerms.canManagePermissions, isTrue);
        expect(adminPerms.canInviteMembers, isTrue);

        // Editor should have content capabilities
        expect(editorPerms.canEditSharedNotes, isTrue);

        // Viewer should have minimal capabilities
        expect(viewerPerms.canEditSharedNotes, isFalse);
      });
    });

    group('Permission Combinations', () {
      test('Admin permissions should include content permissions', () {
        final adminPerms = MemberPermissions.admin();

        expect(adminPerms.hasAdminCapabilities, isTrue);
        expect(adminPerms.canModifyContent, isTrue);
        expect(adminPerms.canShareContent, isTrue);
      });

      test('Content permissions should not include admin permissions', () {
        final editorPerms = MemberPermissions.editor();

        expect(editorPerms.hasAdminCapabilities, isFalse);
        expect(editorPerms.canModifyContent, isTrue);
        expect(editorPerms.canShareContent, isTrue);
      });

      test('Read-only permissions should not include any modification permissions', () {
        final viewerPerms = MemberPermissions.viewer();

        expect(viewerPerms.hasAdminCapabilities, isFalse);
        expect(viewerPerms.canModifyContent, isFalse);
        expect(viewerPerms.canShareContent, isFalse);
      });
    });

    group('Permission Validation Edge Cases', () {
      test('Empty permissions should be valid', () {
        final emptyPerms = MemberPermissions(
          canInviteMembers: false,
          canRemoveMembers: false,
          canShareNotes: false,
          canEditSharedNotes: false,
          canDeleteSharedNotes: false,
          canManagePermissions: false,
        );

        expect(emptyPerms.hasAdminCapabilities, isFalse);
        expect(emptyPerms.canModifyContent, isFalse);
        expect(emptyPerms.canShareContent, isFalse);
      });

      test('Mixed permissions should work correctly', () {
        final mixedPerms = MemberPermissions(
          canInviteMembers: true,    // Admin capability
          canRemoveMembers: false,
          canShareNotes: true,       // Share capability
          canEditSharedNotes: true,  // Modify capability
          canDeleteSharedNotes: false,
          canManagePermissions: false,
        );

        expect(mixedPerms.hasAdminCapabilities, isTrue);
        expect(mixedPerms.canModifyContent, isTrue);
        expect(mixedPerms.canShareContent, isTrue);
      });
    });
  });
}
