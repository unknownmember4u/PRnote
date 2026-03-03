import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:prnote/core/database/note_dao.dart';
import 'package:prnote/models/tag.dart';

const _uuid = Uuid();

/// Global tags state
class TagsNotifier extends StateNotifier<AsyncValue<List<Tag>>> {
  final NoteDao _dao = NoteDao();

  TagsNotifier() : super(const AsyncValue.loading()) {
    loadTags();
  }

  Future<void> loadTags() async {
    try {
      state = const AsyncValue.loading();
      final tags = await _dao.getAllTags();
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Tag> createTag(String name, {String? color}) async {
    final tag = Tag(
      id: _uuid.v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );
    await _dao.insertTag(tag);
    await loadTags();
    return tag;
  }

  Future<void> deleteTag(String id) async {
    await _dao.deleteTag(id);
    await loadTags();
  }

  Future<void> addTagToNote(String noteId, String tagId) async {
    await _dao.addTagToNote(noteId, tagId);
  }

  Future<void> removeTagFromNote(String noteId, String tagId) async {
    await _dao.removeTagFromNote(noteId, tagId);
  }

  Future<List<Tag>> getTagsForNote(String noteId) async {
    return _dao.getTagsForNote(noteId);
  }
}

/// Provider for tags state
final tagsProvider =
    StateNotifierProvider<TagsNotifier, AsyncValue<List<Tag>>>((ref) {
  return TagsNotifier();
});

/// Provider for tags of a specific note
final noteTagsProvider =
    FutureProvider.family<List<Tag>, String>((ref, noteId) async {
  final dao = NoteDao();
  return dao.getTagsForNote(noteId);
});
