import AsyncStorage from '@react-native-async-storage/async-storage';
import * as SQLite from 'expo-sqlite';
import { Folder, Note, ThemeMode } from '../types/models';

const DB_NAME = 'prnote.db';
const PREF_LAST_EDITED_NOTE_ID = 'last_edited_note_id';
const PREF_THEME_MODE = 'theme_mode';

let dbPromise: Promise<SQLite.SQLiteDatabase> | null = null;

const mapNote = (row: any): Note => ({
  id: row.id,
  title: row.title ?? '',
  content: row.content ?? '',
  folderId: row.folder_id ?? null,
  isPinned: Number(row.is_pinned) === 1,
  isFavorite: Number(row.is_favorite) === 1,
  isDeleted: Number(row.is_deleted) === 1,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

const mapFolder = (row: any): Folder => ({
  id: row.id,
  name: row.name,
  sortOrder: Number(row.sort_order ?? 0),
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

export async function getDb() {
  if (!dbPromise) {
    dbPromise = SQLite.openDatabaseAsync(DB_NAME);
  }
  const db = await dbPromise;
  await db.execAsync('PRAGMA foreign_keys = ON;');
  return db;
}

export async function initDatabase() {
  const db = await getDb();

  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS folders (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS notes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      folder_id TEXT,
      is_pinned INTEGER NOT NULL DEFAULT 0,
      is_favorite INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at DESC);
    CREATE INDEX IF NOT EXISTS idx_notes_is_deleted ON notes(is_deleted);
    CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON notes(is_pinned DESC);
  `);

  const folderCount = await db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM folders');
  if (!folderCount || folderCount.count === 0) {
    const now = new Date().toISOString();
    await db.runAsync(
      'INSERT INTO folders (id, name, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
      ['default', 'All Notes', 0, now, now]
    );
  }
}

export async function getAllNotes() {
  const db = await getDb();
  const rows = await db.getAllAsync<any>(
    `SELECT * FROM notes WHERE is_deleted = 0 ORDER BY is_pinned DESC, updated_at DESC`
  );
  return rows.map(mapNote);
}

export async function getNoteById(id: string) {
  const db = await getDb();
  const row = await db.getFirstAsync<any>('SELECT * FROM notes WHERE id = ?', [id]);
  return row ? mapNote(row) : null;
}

export async function createNote() {
  const db = await getDb();
  const now = new Date().toISOString();
  const id = globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random()}`;
  await db.runAsync(
    `INSERT INTO notes (id, title, content, folder_id, is_pinned, is_favorite, is_deleted, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [id, '', '', null, 0, 0, 0, now, now]
  );
  await setLastEditedNoteId(id);
  const note = await getNoteById(id);
  if (!note) throw new Error('Failed to create note');
  return note;
}

export async function updateNote(note: Note) {
  const db = await getDb();
  const now = new Date().toISOString();
  await db.runAsync(
    `UPDATE notes
      SET title = ?, content = ?, folder_id = ?, is_pinned = ?, is_favorite = ?, updated_at = ?
      WHERE id = ?`,
    [
      note.title,
      note.content,
      note.folderId,
      note.isPinned ? 1 : 0,
      note.isFavorite ? 1 : 0,
      now,
      note.id,
    ]
  );
}

export async function togglePin(note: Note) {
  await updateNote({ ...note, isPinned: !note.isPinned });
}

export async function toggleFavorite(note: Note) {
  await updateNote({ ...note, isFavorite: !note.isFavorite });
}

export async function deleteNote(id: string) {
  const db = await getDb();
  await db.runAsync('UPDATE notes SET is_deleted = 1, updated_at = ? WHERE id = ?', [
    new Date().toISOString(),
    id,
  ]);
}

export async function searchNotes(query: string) {
  const db = await getDb();
  const like = `%${query}%`;
  const rows = await db.getAllAsync<any>(
    `SELECT * FROM notes
     WHERE is_deleted = 0 AND (title LIKE ? OR content LIKE ?)
     ORDER BY is_pinned DESC, updated_at DESC`,
    [like, like]
  );
  return rows.map(mapNote);
}

export async function getAllFolders() {
  const db = await getDb();
  const rows = await db.getAllAsync<any>('SELECT * FROM folders ORDER BY sort_order ASC, name ASC');
  return rows.map(mapFolder);
}

export async function createFolder(name: string) {
  const db = await getDb();
  const now = new Date().toISOString();
  const id = globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random()}`;
  await db.runAsync(
    `INSERT INTO folders (id, name, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?)`,
    [id, name, 0, now, now]
  );
}

export async function renameFolder(id: string, name: string) {
  const db = await getDb();
  await db.runAsync('UPDATE folders SET name = ?, updated_at = ? WHERE id = ?', [
    name,
    new Date().toISOString(),
    id,
  ]);
}

export async function deleteFolder(id: string) {
  if (id === 'default') return;
  const db = await getDb();
  await db.runAsync('UPDATE notes SET folder_id = NULL WHERE folder_id = ?', [id]);
  await db.runAsync('DELETE FROM folders WHERE id = ?', [id]);
}

export async function getFolderNoteCount(folderId: string) {
  const db = await getDb();
  const row = await db.getFirstAsync<{ count: number }>(
    'SELECT COUNT(*) as count FROM notes WHERE folder_id = ? AND is_deleted = 0',
    [folderId]
  );
  return row?.count ?? 0;
}

export function setLastEditedNoteId(noteId: string) {
  return AsyncStorage.setItem(PREF_LAST_EDITED_NOTE_ID, noteId);
}

export function getLastEditedNoteId() {
  return AsyncStorage.getItem(PREF_LAST_EDITED_NOTE_ID);
}

export async function getThemeMode() {
  const mode = await AsyncStorage.getItem(PREF_THEME_MODE);
  if (mode === 'light' || mode === 'dark' || mode === 'amoled') return mode as ThemeMode;
  return 'dark';
}

export function setThemeMode(mode: ThemeMode) {
  return AsyncStorage.setItem(PREF_THEME_MODE, mode);
}
