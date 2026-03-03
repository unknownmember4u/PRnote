import 'package:prnote/core/database/database_helper.dart';
import 'package:prnote/models/note.dart';
import 'package:prnote/models/folder.dart';
import 'package:prnote/models/tag.dart';
import 'package:prnote/models/attachment.dart';
import 'package:prnote/models/version.dart';

/// Data Access Object for all database CRUD operations
class NoteDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ══════════════════════════════════════════════════
  // NOTES
  // ══════════════════════════════════════════════════

  Future<int> insertNote(Note note) async {
    final db = await _dbHelper.database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> updateNote(Note note) async {
    final db = await _dbHelper.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> softDeleteNote(String id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'notes',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> permanentlyDeleteNote(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Note?> getNoteById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<List<Note>> getAllNotes({bool includeDeleted = false}) async {
    final db = await _dbHelper.database;
    final where = includeDeleted ? null : 'is_deleted = 0';
    final maps = await db.query(
      'notes',
      where: where,
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<List<Note>> getNotesByFolder(String folderId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'folder_id = ? AND is_deleted = 0',
      whereArgs: [folderId],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<List<Note>> getFavoriteNotes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'is_favorite = 1 AND is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await _dbHelper.database;
    List<Map<String, Object?>> maps;
    try {
      maps = await db.rawQuery('''
        SELECT notes.* FROM notes
        JOIN notes_fts ON notes.rowid = notes_fts.rowid
        WHERE notes_fts MATCH ? AND notes.is_deleted = 0
        ORDER BY rank
      ''', ['"$query"*']);
    } catch (_) {
      final likeQuery = '%$query%';
      maps = await db.query(
        'notes',
        where: 'is_deleted = 0 AND (title LIKE ? OR content LIKE ?)',
        whereArgs: [likeQuery, likeQuery],
        orderBy: 'updated_at DESC',
      );
    }
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<List<Note>> getDeletedNotes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'is_deleted = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<int> restoreNote(String id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'notes',
      {'is_deleted': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ══════════════════════════════════════════════════
  // FOLDERS
  // ══════════════════════════════════════════════════

  Future<int> insertFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return await db.insert('folders', folder.toMap());
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await _dbHelper.database;
    final maps = await db.query('folders', orderBy: 'sort_order ASC, name ASC');
    return maps.map((m) => Folder.fromMap(m)).toList();
  }

  Future<Folder?> getFolderById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('folders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Folder.fromMap(maps.first);
  }

  Future<int> getNoteCountInFolder(String folderId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE folder_id = ? AND is_deleted = 0',
      [folderId],
    );
    return result.first['count'] as int;
  }

  // ══════════════════════════════════════════════════
  // TAGS
  // ══════════════════════════════════════════════════

  Future<int> insertTag(Tag tag) async {
    final db = await _dbHelper.database;
    return await db.insert('tags', tag.toMap());
  }

  Future<int> deleteTag(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Tag>> getAllTags() async {
    final db = await _dbHelper.database;
    final maps = await db.query('tags', orderBy: 'name ASC');
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  Future<void> addTagToNote(String noteId, String tagId) async {
    final db = await _dbHelper.database;
    await db.insert('note_tags', {'note_id': noteId, 'tag_id': tagId});
  }

  Future<void> removeTagFromNote(String noteId, String tagId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'note_tags',
      where: 'note_id = ? AND tag_id = ?',
      whereArgs: [noteId, tagId],
    );
  }

  Future<List<Tag>> getTagsForNote(String noteId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT tags.* FROM tags
      INNER JOIN note_tags ON tags.id = note_tags.tag_id
      WHERE note_tags.note_id = ?
      ORDER BY tags.name ASC
    ''', [noteId]);
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  Future<List<Note>> getNotesByTag(String tagId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT notes.* FROM notes
      INNER JOIN note_tags ON notes.id = note_tags.note_id
      WHERE note_tags.tag_id = ? AND notes.is_deleted = 0
      ORDER BY notes.updated_at DESC
    ''', [tagId]);
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  // ══════════════════════════════════════════════════
  // ATTACHMENTS
  // ══════════════════════════════════════════════════

  Future<int> insertAttachment(Attachment attachment) async {
    final db = await _dbHelper.database;
    return await db.insert('attachments', attachment.toMap());
  }

  Future<int> deleteAttachment(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Attachment>> getAttachmentsForNote(String noteId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'attachments',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Attachment.fromMap(m)).toList();
  }

  // ══════════════════════════════════════════════════
  // VERSIONS
  // ══════════════════════════════════════════════════

  Future<int> insertVersion(NoteVersion version) async {
    final db = await _dbHelper.database;
    return await db.insert('versions', version.toMap());
  }

  Future<List<NoteVersion>> getVersionsForNote(String noteId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'versions',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'version_number DESC',
    );
    return maps.map((m) => NoteVersion.fromMap(m)).toList();
  }

  Future<int> getLatestVersionNumber(String noteId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(version_number) as max_version FROM versions WHERE note_id = ?',
      [noteId],
    );
    return (result.first['max_version'] as int?) ?? 0;
  }
}
