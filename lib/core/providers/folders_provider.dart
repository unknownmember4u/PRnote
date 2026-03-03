import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:prnote/core/database/note_dao.dart';
import 'package:prnote/models/folder.dart';

const _uuid = Uuid();

/// Global folders state
class FoldersNotifier extends StateNotifier<AsyncValue<List<Folder>>> {
  final NoteDao _dao = NoteDao();

  FoldersNotifier() : super(const AsyncValue.loading()) {
    loadFolders();
  }

  Future<void> loadFolders() async {
    try {
      state = const AsyncValue.loading();
      final folders = await _dao.getAllFolders();
      state = AsyncValue.data(folders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Folder> createFolder(String name, {String? parentId, String? color, String? icon}) async {
    final now = DateTime.now();
    final folder = Folder(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      color: color,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insertFolder(folder);
    await loadFolders();
    return folder;
  }

  Future<void> updateFolder(Folder folder) async {
    final updated = folder.copyWith(updatedAt: DateTime.now());
    await _dao.updateFolder(updated);
    await loadFolders();
  }

  Future<void> deleteFolder(String id) async {
    await _dao.deleteFolder(id);
    await loadFolders();
  }

  Future<void> renameFolder(String id, String newName) async {
    final folder = await _dao.getFolderById(id);
    if (folder != null) {
      await updateFolder(folder.copyWith(name: newName));
    }
  }
}

/// Provider for folders state
final foldersProvider =
    StateNotifierProvider<FoldersNotifier, AsyncValue<List<Folder>>>((ref) {
  return FoldersNotifier();
});

/// Provider for folder note counts
final folderNoteCountProvider =
    FutureProvider.family<int, String>((ref, folderId) async {
  final dao = NoteDao();
  return dao.getNoteCountInFolder(folderId);
});
