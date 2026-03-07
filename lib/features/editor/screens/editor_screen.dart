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
import 'package:share_plus/share_plus.dart';

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
        if (context.mounted) context.go('/home');
        return;
      }

      setState(() {
        _currentNote = note;
        _titleController.text = note.title;
        _contentController.text = note.content;
        _isLoading = false;
      });
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
        if (_currentNote == null) return;
        _showShareSheet();
        return;
      case _EditorMenuAction.copyText:
        await Clipboard.setData(ClipboardData(
          text: '${_titleController.text}\n\n${_contentController.text}',
        ));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF26A69A), size: 18),
                const SizedBox(width: 8),
                Text('Copied to clipboard', style: GoogleFonts.inter()),
              ],
            ),
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

  void _showShareSheet() {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nothing to share — add some content first',
              style: GoogleFonts.inter()),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Share Note',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              title.isNotEmpty ? title : 'Untitled',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Options container
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: isLight ? 0.3 : 0.2),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  // Share as text
                  _ShareOption(
                    icon: Icons.text_snippet_outlined,
                    iconColor: const Color(0xFF5C6BC0),
                    title: 'Share as text',
                    subtitle: 'Plain text content only',
                    theme: theme,
                    onTap: () {
                      Navigator.pop(ctx);
                      _shareText(plain: true);
                    },
                  ),
                  Divider(height: 1, indent: 56,
                    color: theme.dividerColor.withValues(alpha: 0.2)),

                  // Share formatted
                  _ShareOption(
                    icon: Icons.article_outlined,
                    iconColor: const Color(0xFF26A69A),
                    title: 'Share formatted',
                    subtitle: 'Title, content & date included',
                    theme: theme,
                    onTap: () {
                      Navigator.pop(ctx);
                      _shareText(plain: false);
                    },
                  ),
                  Divider(height: 1, indent: 56,
                    color: theme.dividerColor.withValues(alpha: 0.2)),

                  // Copy to clipboard
                  _ShareOption(
                    icon: Icons.copy_rounded,
                    iconColor: theme.colorScheme.primary,
                    title: 'Copy to clipboard',
                    subtitle: 'Copy note content for pasting',
                    theme: theme,
                    onTap: () {
                      Navigator.pop(ctx);
                      _copyToClipboard();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _shareText({required bool plain}) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    String shareContent;
    if (plain) {
      shareContent = [
        if (title.isNotEmpty) title,
        if (content.isNotEmpty) content,
      ].join('\n\n');
    } else {
      final date = _currentNote != null
          ? DateFormat('MMMM d, yyyy · h:mm a').format(_currentNote!.updatedAt)
          : '';
      shareContent = [
        if (title.isNotEmpty) '📝 $title',
        if (title.isNotEmpty) '─' * 20,
        if (content.isNotEmpty) content,
        '',
        if (date.isNotEmpty) '📅 $date',
        '— Shared from PRnote',
      ].join('\n');
    }

    await SharePlus.instance.share(
      ShareParams(text: shareContent),
    );
  }

  Future<void> _copyToClipboard() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final text = [
      if (title.isNotEmpty) title,
      if (content.isNotEmpty) content,
    ].join('\n\n');

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF26A69A), size: 18),
            const SizedBox(width: 8),
            Text('Copied to clipboard', style: GoogleFonts.inter()),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
    final topPadding = MediaQuery.of(context).padding.top;
    final isLight = theme.brightness == Brightness.light;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5, color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _saveAndExit();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            SizedBox(height: topPadding),
            // Toolbar
            _buildToolbar(theme, isLight),

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
                        letterSpacing: -0.3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    // Date & save info
                    if (_currentNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                DateFormat('MMM d, yyyy · h:mm a')
                                    .format(_currentNote!.updatedAt),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            if (_lastSaved != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF26A69A).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: Color(0xFF26A69A),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Saved',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF26A69A),
                                      ),
                                    ),
                                  ],
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
                        letterSpacing: 0.1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 16,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
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
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.15),
            width: 0.5,
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
              if (ctx.mounted) ctx.go('/home');
            },
            splashRadius: 22,
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 22,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const Spacer(),

          // Unsaved changes indicator
          AnimatedOpacity(
            opacity: _hasUnsavedChanges ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 7, height: 7,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Word count
          if (_contentController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${_contentController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Pin toggle
          _ToolbarAction(
            icon: _currentNote?.isPinned == true ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            isActive: _currentNote?.isPinned == true,
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.textTheme.bodySmall?.color ?? Colors.grey,
            onTap: () {
              if (_currentNote != null) {
                ref.read(notesProvider.notifier).togglePin(_currentNote!);
                setState(() {
                  _currentNote = _currentNote!.copyWith(isPinned: !_currentNote!.isPinned);
                });
              }
            },
          ),

          // Favorite toggle
          _ToolbarAction(
            icon: _currentNote?.isFavorite == true ? Icons.star_rounded : Icons.star_outline_rounded,
            isActive: _currentNote?.isFavorite == true,
            activeColor: const Color(0xFFFFB300),
            inactiveColor: theme.textTheme.bodySmall?.color ?? Colors.grey,
            onTap: () {
              if (_currentNote != null) {
                ref.read(notesProvider.notifier).toggleFavorite(_currentNote!);
                setState(() {
                  _currentNote = _currentNote!.copyWith(isFavorite: !_currentNote!.isFavorite);
                });
              }
            },
          ),

          // More menu
          PopupMenuButton<_EditorMenuAction>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: isLight
                ? theme.cardTheme.color
                : theme.colorScheme.surface,
            elevation: isLight ? 4 : 8,
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              _buildMenuItem(
                Icons.share_outlined, 'Share',
                theme.textTheme.titleMedium?.color ?? Colors.white,
                _EditorMenuAction.share,
              ),
              _buildMenuItem(
                Icons.copy_rounded, 'Copy text',
                theme.textTheme.titleMedium?.color ?? Colors.white,
                _EditorMenuAction.copyText,
              ),
              _buildMenuItem(
                Icons.history_rounded, 'Version history',
                theme.textTheme.titleMedium?.color ?? Colors.white,
                _EditorMenuAction.versionHistory,
              ),
              const PopupMenuDivider(),
              _buildMenuItem(
                Icons.delete_outline_rounded, 'Move to trash',
                theme.colorScheme.error,
                _EditorMenuAction.moveToTrash,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_EditorMenuAction> _buildMenuItem(
    IconData icon, String label, Color color, _EditorMenuAction action,
  ) {
    return PopupMenuItem<_EditorMenuAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}

// ─── Toolbar Action Button ─────────────────────────
class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _ToolbarAction({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 20,
      icon: Icon(
        icon,
        size: 22,
        color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.5),
      ),
    );
  }
}

// ─── Share Option Tile ───────────────────────────────
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
        ),
        onTap: onTap,
      ),
    );
  }
}
