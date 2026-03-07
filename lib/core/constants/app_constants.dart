/// App-wide constants for PRnote
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'PRnote';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.prnote.app';

  // Database
  static const String dbName = 'prnote.db';
  static const int dbVersion = 1;

  // Auto-save
  static const Duration autoSaveInterval = Duration(seconds: 3);

  // Preferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLastEditedNoteId = 'last_edited_note_id';
  static const String prefIsFirstLaunch = 'is_first_launch';
  static const String prefEditorFontSize = 'editor_font_size';
  static const String prefEditorFontFamily = 'editor_font_family';
  static const String prefEditorTextColor = 'editor_text_color';
  static const String prefEditorLineHeight = 'editor_line_height';
  static const String prefAutoSaveInterval = 'auto_save_interval';

  // Theme modes
  static const String themeModeLight = 'light';
  static const String themeModeAmoled = 'amoled';

  // Default values
  static const String defaultFolderName = 'All Notes';
  static const String defaultFolderId = 'default';

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
