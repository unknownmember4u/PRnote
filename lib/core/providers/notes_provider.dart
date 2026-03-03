import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:prnote/core/database/note_dao.dart';
import 'package:prnote/models/note.dart';
import 'package:prnote/models/version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prnote/core/constants/app_constants.dart';

const _uuid = Uuid();

/// Global notes state
class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteDao _dao = NoteDao();

  NotesNotifier() : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      state = const AsyncValue.loading();
      final notes = await _dao.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Note> createNote({String? folderId, String? title}) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title ?? '',
      content: '',
      folderId: folderId,
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insertNote(note);
    await _setLastEditedNoteId(note.id);
    await loadNotes();
    return note;
  }

  Future<void> updateNote(Note note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _dao.updateNote(updated);
    await loadNotes();
  }

  Future<void> autoSave(Note note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _dao.updateNote(updated);
    // Don't reload to avoid UI flickering during typing
    // Update the state inline
    state.whenData((notes) {
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        final updatedList = List<Note>.from(notes);
        updatedList[index] = updated;
        state = AsyncValue.data(updatedList);
      }
    });
  }

  Future<void> saveVersion(Note note) async {
    final versionNum = await _dao.getLatestVersionNumber(note.id);
    final version = NoteVersion(
      id: _uuid.v4(),
      noteId: note.id,
      title: note.title,
      content: note.content,
      versionNumber: versionNum + 1,
      createdAt: DateTime.now(),
    );
    await _dao.insertVersion(version);
  }

  Future<void> deleteNote(String id) async {
    await _dao.softDeleteNote(id);
    await loadNotes();
  }

  Future<void> permanentlyDeleteNote(String id) async {
    await _dao.permanentlyDeleteNote(id);
    await loadNotes();
  }

  Future<void> restoreNote(String id) async {
    await _dao.restoreNote(id);
    await loadNotes();
  }

  Future<void> togglePin(Note note) async {
    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  Future<void> toggleFavorite(Note note) async {
    await updateNote(note.copyWith(isFavorite: !note.isFavorite));
  }

  Future<void> moveToFolder(String noteId, String? folderId) async {
    final note = await _dao.getNoteById(noteId);
    if (note != null) {
      await updateNote(note.copyWith(folderId: folderId));
    }
  }

  Future<void> _setLastEditedNoteId(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLastEditedNoteId, noteId);
  }

  Future<String?> getLastEditedNoteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefLastEditedNoteId);
  }
}

/// Provider for notes state
final notesProvider =
    StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  return NotesNotifier();
});

/// Provider for search results
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final dao = NoteDao();
  return dao.searchNotes(query);
});

/// Provider for deleted notes
final deletedNotesProvider = FutureProvider<List<Note>>((ref) async {
  final dao = NoteDao();
  return dao.getDeletedNotes();
});

/// Provider for favorite notes
final favoriteNotesProvider = FutureProvider<List<Note>>((ref) async {
  final dao = NoteDao();
  return dao.getFavoriteNotes();
});
