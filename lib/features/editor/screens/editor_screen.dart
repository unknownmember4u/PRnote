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
import 'package:prnote/core/providers/editor_settings_provider.dart';
import 'package:prnote/models/version.dart';
import 'package:prnote/features/editor/widgets/colored_text_controller.dart';

enum _EditorMenuAction { share, copyText, versionHistory, moveToTrash }

class EditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  const EditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _titleController;
  late ColoredTextController _contentController;
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
    _contentController = ColoredTextController();
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
        _contentController.deserializeContent(note.content);
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
    
    final autoSaveSeconds = ref.read(editorSettingsProvider).autoSaveIntervalSeconds;
    if (autoSaveSeconds > 0) {
      _autoSaveTimer = Timer(Duration(seconds: autoSaveSeconds), _performAutoSave);
    } else {
      setState(() {}); // Trigger rebuild to show unsaved indicator when manually typing
    }
  }

  Future<void> _performAutoSave() async {
    if (_currentNote == null || !_hasUnsavedChanges) return;

    final updated = _currentNote!.copyWith(
      title: _titleController.text,
      content: _contentController.serializedContent,
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

  Future<void> _manualSave() async {
    if (_hasUnsavedChanges) {
      await _performAutoSave();
    }
    if (_currentNote != null) {
      await ref.read(notesProvider.notifier).saveVersion(_currentNote!);
      // Refresh version history list automatically if we create a new snapshot
      ref.invalidate(noteVersionsProvider(_currentNote!.id));
    }
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF26A69A), size: 18),
            const SizedBox(width: 8),
            Text('Saved successfully', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveAndExit() async {
    _autoSaveTimer?.cancel();
    if (_hasUnsavedChanges && _currentNote != null) {
      final updated = _currentNote!.copyWith(
        title: _titleController.text,
        content: _contentController.serializedContent,
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
        if (_currentNote == null) return;
        _showVersionHistorySheet();
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

  void _showVersionHistorySheet() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, child) {
              final versionsAsync = ref.watch(noteVersionsProvider(_currentNote!.id));
              return Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                child: Column(
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
                    Text('Version History',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: versionsAsync.when(
                        loading: () => Center(
                          child: CircularProgressIndicator(color: theme.colorScheme.primary),
                        ),
                        error: (e, st) => Center(child: Text('Error loading versions', style: GoogleFonts.inter())),
                        data: (versions) {
                          if (versions.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text('No version history yet.\\nTap "Save Note" to create your first snapshot.',
                                  style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          
                          return ListView.separated(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: versions.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
                            itemBuilder: (context, index) {
                              final version = versions[index];
                              final date = DateFormat('MMM d, yyyy · h:mm a').format(version.createdAt);
                              
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  child: Text('v${version.versionNumber}', 
                                    style: GoogleFonts.inter(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                                title: Text(version.title.isEmpty ? 'Untitled' : version.title,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1),
                                subtitle: Text(date,
                                  style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 13)),
                                trailing: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  icon: const Icon(Icons.restore_rounded, size: 18),
                                  label: Text('Restore', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _restoreVersion(version);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _restoreVersion(NoteVersion version) {
    _titleController.text = version.title;
    _contentController.deserializeContent(version.content);
    _onTextChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF26A69A), size: 18),
            const SizedBox(width: 8),
            Text('Restored Version ${version.versionNumber}', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
        duration: const Duration(seconds: 2),
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
        floatingActionButton: AnimatedScale(
          scale: _hasUnsavedChanges ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: FloatingActionButton.extended(
            onPressed: _manualSave,
            backgroundColor: theme.colorScheme.primary, // Yellow theme color
            foregroundColor: Colors.black87, // High contrast with yellow
            icon: const Icon(Icons.save_rounded),
            label: Text('Save Note', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ),
        body: Column(
          children: [
            SizedBox(height: topPadding),
            // Toolbar
            _buildToolbar(theme, isLight, ref.watch(editorSettingsProvider)),

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
                      style: ref.watch(editorSettingsProvider).getTextStyle(
                        fontSizeOverride: 26,
                        fontWeight: FontWeight.w700,
                        defaultColor: theme.textTheme.displayLarge?.color,
                        heightOverride: 1.3,
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
                            Text(
                              DateFormat('MMM d, yyyy · h:mm a').format(_currentNote!.updatedAt),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '·',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!_hasUnsavedChanges) ...[
                              Icon(Icons.cloud_done_rounded, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Saved',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                ),
                              ),
                            ] else ...[
                              Icon(Icons.edit_note_rounded, size: 16, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Text(
                                'Unsaved changes',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Content field
                    TextField(
                      controller: _contentController,
                      style: ref.watch(editorSettingsProvider).getTextStyle(
                        fontWeight: FontWeight.w400,
                        defaultColor: theme.textTheme.bodyLarge?.color,
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

  void _showFontSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FontSettingsBottomSheet(controller: _contentController),
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isLight, EditorSettings settings) {
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

          // Manual Save indicator explicitly removed from here to use FAB
          AnimatedOpacity(
            opacity: _hasUnsavedChanges ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Unsaved',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

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

          // Font options toggle
          _ToolbarAction(
            icon: Icons.text_format_rounded,
            isActive: false,
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.textTheme.bodySmall?.color ?? Colors.grey,
            onTap: _showFontSettingsSheet,
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

// ─── Font Settings Bottom Sheet ───────────────────────
// ─── Font Settings Bottom Sheet ───────────────────────
class _FontSettingsBottomSheet extends ConsumerWidget {
  final ColoredTextController controller;

  const _FontSettingsBottomSheet({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(editorSettingsProvider);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 40),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final currentStyle = controller.currentStyleAtCursor;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Typography',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      _FormatIconButton(
                        icon: Icons.format_italic_rounded,
                        isSelected: currentStyle.isItalic,
                        onTap: () => controller.toggleItalic(),
                      ),
                      const SizedBox(width: 8),
                      _FormatIconButton(
                        icon: Icons.format_underlined_rounded,
                        isSelected: currentStyle.isUnderline,
                        onTap: () => controller.toggleUnderline(),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Size slider
              Row(
                children: [
                  Text('A', style: GoogleFonts.inter(fontSize: 14)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        thumbColor: theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: settings.fontSize,
                        min: 12.0,
                        max: 32.0,
                        divisions: 20,
                        onChanged: (val) {
                          ref.read(editorSettingsProvider.notifier).updateFontSize(val);
                        },
                      ),
                    ),
                  ),
                  Text('A', style: GoogleFonts.inter(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 16),
              
              // Font family selection
              Text(
                'Font Family (Selected Text)',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: EditorSettings.availableFonts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final font = EditorSettings.availableFonts[index];
                    final isSelected = (currentStyle.font ?? settings.fontFamily) == font;
                    
                    return InkWell(
                      onTap: () {
                        controller.fontSelection(font == settings.fontFamily ? null : font);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          font,
                          style: settings.copyWith(fontFamily: font, clearTextColor: true).getTextStyle(
                            fontSizeOverride: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            defaultColor: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Line Height slider
              Text(
                'Line Spacing',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textTheme.bodySmall?.color),
              ),
              Row(
                children: [
                  Icon(Icons.format_line_spacing_rounded, size: 18, color: theme.textTheme.bodySmall?.color),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        thumbColor: theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: settings.lineHeight,
                        min: 1.0,
                        max: 3.0,
                        divisions: 10,
                        onChanged: (val) {
                          ref.read(editorSettingsProvider.notifier).updateLineHeight(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              // Text Color selection
              Text(
                'Text Color',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Default theme color option
                    _ColorOption(
                      color: null,
                      themeColor: theme.textTheme.bodyLarge?.color,
                      isSelected: currentStyle.color == null,
                      onTap: () => controller.colorSelection(null),
                    ),
                    _ColorOption(color: const Color(0xFFEF5350), isSelected: currentStyle.color == const Color(0xFFEF5350), onTap: () => controller.colorSelection(const Color(0xFFEF5350))),
                    _ColorOption(color: const Color(0xFF42A5F5), isSelected: currentStyle.color == const Color(0xFF42A5F5), onTap: () => controller.colorSelection(const Color(0xFF42A5F5))),
                    _ColorOption(color: const Color(0xFF66BB6A), isSelected: currentStyle.color == const Color(0xFF66BB6A), onTap: () => controller.colorSelection(const Color(0xFF66BB6A))),
                    _ColorOption(color: const Color(0xFFFFCA28), isSelected: currentStyle.color == const Color(0xFFFFCA28), onTap: () => controller.colorSelection(const Color(0xFFFFCA28))),
                    _ColorOption(color: const Color(0xFFAB47BC), isSelected: currentStyle.color == const Color(0xFFAB47BC), onTap: () => controller.colorSelection(const Color(0xFFAB47BC))),
                    _ColorOption(color: const Color(0xFF8D6E63), isSelected: currentStyle.color == const Color(0xFF8D6E63), onTap: () => controller.colorSelection(const Color(0xFF8D6E63))),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _FormatIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatIconButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
        ),
      ),
    );
  }
}

// ─── Color Option Widget ────────────────────────────────
class _ColorOption extends StatelessWidget {
  final Color? color;
  final Color? themeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    this.color,
    this.themeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? themeColor ?? Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: isSelected ? 3 : 0,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
        ),
        child: isSelected
          ? Icon(Icons.check_rounded, color: displayColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 24)
          : color == null 
            ? Icon(Icons.format_color_text_rounded, color: displayColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20)
            : null,
      ),
    );
  }
}
