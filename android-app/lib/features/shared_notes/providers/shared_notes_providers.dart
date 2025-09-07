import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/shared_note.dart';
import '../../../models/shared_note_comment.dart';
import '../../../models/note_permission.dart';
import '../../family/services/shared_notes_service.dart';

// Provider for shared notes service
final sharedNotesServiceProvider = Provider<SharedNotesService>((ref) {
  // TODO: Get these from their respective providers
  throw UnimplementedError('SharedNotesService needs proper dependency injection');
});

// Provider for all shared notes
final sharedNotesProvider = StateNotifierProvider<SharedNotesNotifier, AsyncValue<List<SharedNote>>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return SharedNotesNotifier(service);
});

// Provider for shared notes by current user
final mySharedNotesProvider = StateNotifierProvider<MySharedNotesNotifier, AsyncValue<List<SharedNote>>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return MySharedNotesNotifier(service);
});

// Provider for pending shared note approvals
final pendingSharedNotesProvider = StateNotifierProvider<PendingSharedNotesNotifier, AsyncValue<List<SharedNote>>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return PendingSharedNotesNotifier(service);
});

// Provider for a specific shared note
final sharedNoteProvider = FutureProvider.family<SharedNote?, String>((ref, noteId) async {
  final service = ref.watch(sharedNotesServiceProvider);
  return await service.getSharedNote(noteId);
});

// Provider for sharing a note
final shareNoteProvider = StateNotifierProvider<ShareNoteNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return ShareNoteNotifier(service);
});

// Provider for approving/rejecting shared notes
final approveSharedNoteProvider = StateNotifierProvider<ApproveSharedNoteNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return ApproveSharedNoteNotifier(service);
});

// Provider for revoking shared note access
final revokeSharedNoteProvider = StateNotifierProvider<RevokeSharedNoteNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return RevokeSharedNoteNotifier(service);
});

// Provider for comments on a shared note
final sharedNoteCommentsProvider = FutureProvider.family<List<SharedNoteComment>, String>((ref, sharedNoteId) async {
  final service = ref.watch(sharedNotesServiceProvider);
  return await service.getComments(sharedNoteId);
});

// Provider for adding comments
final addCommentProvider = StateNotifierProvider<AddCommentNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return AddCommentNotifier(service);
});

// Provider for updating comments
final updateCommentProvider = StateNotifierProvider<UpdateCommentNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return UpdateCommentNotifier(service);
});

// Provider for deleting comments
final deleteCommentProvider = StateNotifierProvider<DeleteCommentNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return DeleteCommentNotifier(service);
});

// Provider for toggling comment likes
final toggleCommentLikeProvider = StateNotifierProvider<ToggleCommentLikeNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(sharedNotesServiceProvider);
  return ToggleCommentLikeNotifier(service);
});

// Notifier classes
class SharedNotesNotifier extends StateNotifier<AsyncValue<List<SharedNote>>> {
  final SharedNotesService _service;

  SharedNotesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadSharedNotes();
  }

  Future<void> loadSharedNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _service.getSharedNotes();
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadSharedNotes();
  }
}

class MySharedNotesNotifier extends StateNotifier<AsyncValue<List<SharedNote>>> {
  final SharedNotesService _service;

  MySharedNotesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadMySharedNotes();
  }

  Future<void> loadMySharedNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _service.getMySharedNotes();
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadMySharedNotes();
  }
}

class PendingSharedNotesNotifier extends StateNotifier<AsyncValue<List<SharedNote>>> {
  final SharedNotesService _service;

  PendingSharedNotesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadPendingApprovals();
  }

  Future<void> loadPendingApprovals() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _service.getPendingApprovals();
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadPendingApprovals();
  }
}

class ShareNoteNotifier extends StateNotifier<AsyncValue<void>> {
  final SharedNotesService _service;

  ShareNoteNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> shareNote({
    required String noteId,
    required String title,
    required NotePermission permission,
    String? description,
    bool requiresApproval = false,
    DateTime? expiresAt,
    bool allowCollaboration = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.shareNote(
        noteId: noteId,
        title: title,
        permission: permission,
        description: description,
        requiresApproval: requiresApproval,
        expiresAt: expiresAt,
        allowCollaboration: allowCollaboration,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class ApproveSharedNoteNotifier extends StateNotifier<AsyncValue<void>> {
  final SharedNotesService _service;

  ApproveSharedNoteNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> approveSharedNote(String sharedNoteId) async {
    state = const AsyncValue.loading();
    try {
      await _service.approveSharedNote(sharedNoteId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectSharedNote(String sharedNoteId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _service.rejectSharedNote(sharedNoteId, reason: reason);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class RevokeSharedNoteNotifier extends StateNotifier<AsyncValue<void>> {
  final SharedNotesService _service;

  RevokeSharedNoteNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> revokeSharedNote(String sharedNoteId) async {
    state = const AsyncValue.loading();
    try {
      await _service.revokeSharedNote(sharedNoteId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class AddCommentNotifier extends StateNotifier<AsyncValue<void>> {
  final SharedNotesService _service;

  AddCommentNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> addComment({
    required String sharedNoteId,
    required String content,
    String? parentCommentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.addComment(
        sharedNoteId: sharedNoteId,
        content: content,
        parentCommentId: parentCommentId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class UpdateCommentNotifier extends StateNotifier<AsyncValue<void>> {
  final SharedNotesService _service;

  UpdateCommentNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> updateComment({
    required String sharedNoteId,
    required String commentId,
    required String content,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateComment(
        sharedNoteId: sharedNoteId,
        commentId: commentId,
        content: content,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class DeleteCommentNotifier extends StateNotifier<AsyncValue<void>> {
  final SharedNotesService _service;

  DeleteCommentNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> deleteComment({
    required String sharedNoteId,
    required String commentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteComment(
        sharedNoteId: sharedNoteId,
        commentId: commentId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class ToggleCommentLikeNotifier extends StateNotifier<AsyncValue<void>> {
  final SharedNotesService _service;

  ToggleCommentLikeNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> toggleLike({
    required String sharedNoteId,
    required String commentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.toggleCommentLike(
        sharedNoteId: sharedNoteId,
        commentId: commentId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
