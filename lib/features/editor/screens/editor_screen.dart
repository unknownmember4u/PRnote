import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prnote/core/providers/notes_provider.dart';
import 'package:prnote/core/constants/app_constants.dart';
import 'package:prnote/core/database/note_dao.dart';
import 'package:prnote/models/note.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _EditorMenuAction { share, copyText, versionHistory, moveToTrash }

class EditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  const EditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Timer? _autoSaveTimer;
  Note? _currentNote;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSaved;
  final NoteDao _dao = NoteDao();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId == 'new') {
      final note = await ref.read(notesProvider.notifier).createNote();
      if (!mounted) return;
      setState(() {
        _currentNote = note;
        _isLoading = false;
      });
      _startAutoSave();
    } else {
      final note = await _dao.getNoteById(widget.noteId);
      if (!mounted) return;

      if (note == null) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          context.go('/home');
        }
        return;
      }

      setState(() {
        _currentNote = note;
        _titleController.text = note.title;
        _contentController.text = note.content;
        _isLoading = false;
      });
      // Save as last edited
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefLastEditedNoteId, note.id);
      _startAutoSave();
    }
  }

  void _startAutoSave() {
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _hasUnsavedChanges = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(AppConstants.autoSaveInterval, _performAutoSave);
  }

  Future<void> _performAutoSave() async {
    if (_currentNote == null || !_hasUnsavedChanges) return;

    final updated = _currentNote!.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );

    await ref.read(notesProvider.notifier).autoSave(updated);

    if (!mounted) return;
    setState(() {
      _currentNote = updated;
      _hasUnsavedChanges = false;
      _lastSaved = DateTime.now();
    });
  }

  Future<void> _saveAndExit() async {
    _autoSaveTimer?.cancel();
    if (_hasUnsavedChanges && _currentNote != null) {
      final updated = _currentNote!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
      );
      await ref.read(notesProvider.notifier).updateNote(updated);
      // Save version on exit
      await ref.read(notesProvider.notifier).saveVersion(updated);
      if (!mounted) return;
      setState(() {
        _currentNote = updated;
        _hasUnsavedChanges = false;
        _lastSaved = DateTime.now();
      });
    }
  }

  Future<void> _onMenuSelected(_EditorMenuAction action) async {
    switch (action) {
      case _EditorMenuAction.share:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share coming soon', style: GoogleFonts.inter()),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      case _EditorMenuAction.copyText:
        await Clipboard.setData(ClipboardData(
          text: '${_titleController.text}\n\n${_contentController.text}',
        ));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied to clipboard', style: GoogleFonts.inter()),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      case _EditorMenuAction.versionHistory:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Version history coming soon', style: GoogleFonts.inter()),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      case _EditorMenuAction.moveToTrash:
        if (_currentNote == null) return;
        await ref.read(notesProvider.notifier).deleteNote(_currentNote!.id);
        if (!mounted) return;
        context.go('/home');
        return;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _saveAndExit();
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(theme),

              // Editor
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextField(
                        controller: _titleController,
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.displayLarge?.color,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodySmall?.color?.withAlpha((0.4 * 255).round()),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      // Date info
                      if (_currentNote != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 16),
                          child: Row(
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy · h:mm a')
                                    .format(_currentNote!.updatedAt),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color?.withAlpha((0.5 * 255).round()),
                                ),
                              ),
                              if (_lastSaved != null) ...[
                                Text(
                                  ' · ',
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color?.withAlpha((0.3 * 255).round()),
                                  ),
                                ),
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: const Color(0xFF26A69A),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Saved',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF26A69A),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Content field
                      TextField(
                        controller: _contentController,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: theme.textTheme.bodyLarge?.color,
                          height: 1.7,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Start writing...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16,
                            color: theme.textTheme.bodySmall?.color?.withAlpha((0.4 * 255).round()),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.1 * 255).round()),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () async {
              final ctx = context;
              await _saveAndExit();
              if (ctx.mounted) {
                ctx.go('/home');
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const Spacer(),

          // Auto-save indicator
          if (_hasUnsavedChanges)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFC107),
                shape: BoxShape.circle,
              ),
            ),

          // Actions
          IconButton(
            onPressed: () {
              if (_currentNote != null) {
                ref.read(notesProvider.notifier).togglePin(_currentNote!);
                setState(() {
                  _currentNote = _currentNote!.copyWith(
                    isPinned: !_currentNote!.isPinned,
                  );
                });
              }
            },
            icon: Icon(
              _currentNote?.isPinned == true
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              size: 22,
              color: _currentNote?.isPinned == true
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
          IconButton(
            onPressed: () {
              if (_currentNote != null) {
                ref.read(notesProvider.notifier).toggleFavorite(_currentNote!);
                setState(() {
                  _currentNote = _currentNote!.copyWith(
                    isFavorite: !_currentNote!.isFavorite,
                  );
                });
              }
            },
            icon: Icon(
              _currentNote?.isFavorite == true
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 22,
              color: _currentNote?.isFavorite == true
                  ? const Color(0xFFEF4444)
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
          PopupMenuButton<_EditorMenuAction>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: theme.textTheme.bodySmall?.color,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: theme.colorScheme.surface,
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem<_EditorMenuAction>(
                value: _EditorMenuAction.share,
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, size: 20, color: theme.textTheme.titleMedium?.color),
                    const SizedBox(width: 12),
                    Text('Share', style: GoogleFonts.inter(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem<_EditorMenuAction>(
                value: _EditorMenuAction.copyText,
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 20, color: theme.textTheme.titleMedium?.color),
                    const SizedBox(width: 12),
                    Text('Copy text', style: GoogleFonts.inter(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem<_EditorMenuAction>(
                value: _EditorMenuAction.versionHistory,
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: theme.textTheme.titleMedium?.color),
                    const SizedBox(width: 12),
                    Text('Version history', style: GoogleFonts.inter(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<_EditorMenuAction>(
                value: _EditorMenuAction.moveToTrash,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Text(
                      'Move to trash',
                      style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
