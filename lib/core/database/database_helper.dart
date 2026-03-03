import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:prnote/core/constants/app_constants.dart';

/// Singleton database helper for offline-first SQLite storage
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Notes table
    batch.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        folder_id TEXT,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        color TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    ''');

    // Folders table
    batch.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        color TEXT,
        icon TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    ''');

    // Tags table
    batch.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Note-Tags junction table
    batch.execute('''
      CREATE TABLE note_tags (
        note_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // Attachments table
    batch.execute('''
      CREATE TABLE attachments (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        type TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    // Versions table for note history
    batch.execute('''
      CREATE TABLE versions (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        version_number INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    batch.execute('CREATE INDEX idx_notes_folder_id ON notes(folder_id)');
    batch.execute('CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC)');
    batch.execute('CREATE INDEX idx_notes_is_deleted ON notes(is_deleted)');
    batch.execute('CREATE INDEX idx_notes_is_pinned ON notes(is_pinned)');
    batch.execute('CREATE INDEX idx_notes_is_favorite ON notes(is_favorite)');
    batch.execute('CREATE INDEX idx_note_tags_note_id ON note_tags(note_id)');
    batch.execute('CREATE INDEX idx_note_tags_tag_id ON note_tags(tag_id)');
    batch.execute('CREATE INDEX idx_attachments_note_id ON attachments(note_id)');
    batch.execute('CREATE INDEX idx_versions_note_id ON versions(note_id)');
    batch.execute('CREATE INDEX idx_folders_parent_id ON folders(parent_id)');

    // Insert default folder
    batch.execute('''
      INSERT INTO folders (id, name, sort_order, created_at, updated_at) 
      VALUES ('${AppConstants.defaultFolderId}', '${AppConstants.defaultFolderName}', 0, 
              datetime('now'), datetime('now'))
    ''');

    await batch.commit(noResult: true);

    // Some SQLite builds (older Android devices) do not support FTS5.
    await _tryCreateFtsSchema(db);
  }

  Future<void> _tryCreateFtsSchema(Database db) async {
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE notes_fts USING fts5(
          title,
          content,
          content='notes',
          content_rowid='rowid'
        )
      ''');
      await db.execute('''
        CREATE TRIGGER notes_ai AFTER INSERT ON notes BEGIN
          INSERT INTO notes_fts(rowid, title, content) VALUES (new.rowid, new.title, new.content);
        END
      ''');
      await db.execute('''
        CREATE TRIGGER notes_ad AFTER DELETE ON notes BEGIN
          INSERT INTO notes_fts(notes_fts, rowid, title, content) VALUES('delete', old.rowid, old.title, old.content);
        END
      ''');
      await db.execute('''
        CREATE TRIGGER notes_au AFTER UPDATE ON notes BEGIN
          INSERT INTO notes_fts(notes_fts, rowid, title, content) VALUES('delete', old.rowid, old.title, old.content);
          INSERT INTO notes_fts(rowid, title, content) VALUES (new.rowid, new.title, new.content);
        END
      ''');
    } catch (_) {
      // FTS is optional; search falls back to LIKE queries in NoteDao.
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
