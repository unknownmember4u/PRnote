import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prnote/core/providers/notes_provider.dart';
import 'package:prnote/features/home/widgets/note_card.dart';
import 'package:prnote/features/home/widgets/empty_state.dart';
import 'package:prnote/features/search/widgets/search_overlay.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prnote/core/widgets/prnote_logo.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:prnote/models/note.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _selectedNotes = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedNotes.contains(id)) {
        _selectedNotes.remove(id);
        if (_selectedNotes.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotes.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNotes.clear();
      _isSelectionMode = false;
    });
  }

  void _selectAll(List<Note> notes) {
    setState(() {
      _selectedNotes.addAll(notes.map((n) => n.id));
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showNoteOptions(BuildContext context, WidgetRef ref, Note note) {
    final theme = Theme.of(context);

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
            Text(
              note.plainTitle.isNotEmpty ? note.plainTitle : 'Untitled Note',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            
            _buildOption(
              icon: Icons.copy_rounded,
              color: theme.textTheme.titleMedium?.color ?? Colors.black,
              label: 'Copy Content',
              onTap: () async {
                final txt = '${note.plainTitle}\n\n${note.plainContent}'.trim();
                await Clipboard.setData(ClipboardData(text: txt));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied to clipboard', style: GoogleFonts.inter())),
                  );
                }
              },
            ),
            _buildOption(
              icon: Icons.share_rounded,
              color: theme.textTheme.titleMedium?.color ?? Colors.black,
              label: 'Share',
              onTap: () {
                Navigator.pop(ctx);
                final txt = '${note.plainTitle}\n\n${note.plainContent}'.trim();
                if (txt.isNotEmpty) {
                  // ignore: deprecated_member_use
                  Share.share(txt);
                }
              },
            ),
            _buildOption(
              icon: Icons.backup_rounded,
              color: theme.colorScheme.primary,
              label: 'Backup (Export)',
              onTap: () {
                Navigator.pop(ctx);
                final txt = '${note.plainTitle}\n\n${note.plainContent}'.trim();
                if (txt.isNotEmpty) {
                  // Sharing a file-like output or just standard share
                  // ignore: deprecated_member_use
                  Share.share(txt, subject: '${note.plainTitle} Backup');
                }
              },
            ),
            const Divider(height: 24),
            _buildOption(
              icon: Icons.delete_outline_rounded,
              color: theme.colorScheme.error,
              label: 'Move to trash',
              onTap: () {
                ref.read(notesProvider.notifier).deleteNote(note.id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: GoogleFonts.inter(color: color, fontSize: 15, fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildNoteItem(BuildContext context, ThemeData theme, bool isLight, Note note) {
    final isSelected = _selectedNotes.contains(note.id);
    return Stack(
      children: [
        NoteCard(
          note: note,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(note.id);
            } else {
              context.push('/editor/${note.id}');
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _toggleSelection(note.id);
              });
            } else {
              _showNoteOptions(context, ref, note);
            }
          },
        ),
        if (_isSelectionMode)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        if (isSelected)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: isLight ? Colors.white : Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final isLight = theme.brightness == Brightness.light;

    Future<String> getSelectedText() async {
      final notes = ref.read(notesProvider).valueOrNull ?? [];
      final selected = notes.where((n) => _selectedNotes.contains(n.id)).toList();
      return selected.map((n) => '${n.plainTitle}\n\n${n.plainContent}').join('\n\n---\n\n').trim();
    }

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
              ),
              title: Text(
                '${_selectedNotes.length} Selected',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all_rounded),
                  tooltip: 'Select All',
                  onPressed: () {
                    final notes = ref.read(notesProvider).valueOrNull ?? [];
                    if (notes.isNotEmpty) {
                      _selectAll(notes);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy',
                  onPressed: () async {
                    if (_selectedNotes.isEmpty) return;
                    final text = await getSelectedText();
                    if (text.isNotEmpty) {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied to clipboard', style: GoogleFonts.inter())),
                        );
                      }
                    }
                    _clearSelection();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share',
                  onPressed: () async {
                    if (_selectedNotes.isEmpty) return;
                    final text = await getSelectedText();
                    if (text.isNotEmpty) {
                      // ignore: deprecated_member_use
                      Share.share(text);
                    }
                    _clearSelection();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.backup_rounded),
                  tooltip: 'Backup (Export)',
                  onPressed: () async {
                    if (_selectedNotes.isEmpty) return;
                    final text = await getSelectedText();
                    if (text.isNotEmpty) {
                      // ignore: deprecated_member_use
                      Share.share(text, subject: 'PRnote Backup');
                    }
                    _clearSelection();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  tooltip: 'Move to trash',
                  onPressed: () {
                    for (final id in _selectedNotes) {
                      ref.read(notesProvider.notifier).deleteNote(id);
                    }
                    _clearSelection();
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + (size.height * 0.02), 20, 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Logo + date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const PRnoteLogo(fontSize: 24.0),
                      // Date badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('MMM d').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Greeting + note count
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            notesAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (notes) => Text(
                                '${notes.length} note${notes.length != 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Search Bar (full-width, tappable) ──
                  GestureDetector(
                    onTap: () => SearchOverlay.show(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: isLight
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: isLight ? 0.4 : 0.25),
                          width: 0.8,
                        ),
                        boxShadow: isLight
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search notes...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 4)),

          // Notes list
          notesAsync.when(
            loading: () => SliverFillRemaining(
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 44,
                      color: theme.colorScheme.error.withValues(alpha: 0.6)),
                    const SizedBox(height: 16),
                    Text('Something went wrong',
                      style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleMedium?.color)),
                    const SizedBox(height: 6),
                    Text('Tap to retry',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5))),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => ref.read(notesProvider.notifier).loadNotes(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (notes) {
              if (notes.isEmpty) {
                return const SliverFillRemaining(child: EmptyState());
              }

              final pinnedNotes = notes.where((n) => n.isPinned).toList();
              final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    // Pinned section
                    if (pinnedNotes.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          icon: Icons.push_pin_rounded,
                          label: 'PINNED',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SliverAlignedGrid.count(
                        crossAxisCount: size.width > 600 ? 3 : (size.width > 400 ? 2 : 1),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: pinnedNotes.length,
                        itemBuilder: (context, index) {
                          final note = pinnedNotes[index];
                          return _buildNoteItem(context, theme, isLight, note);
                        },
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],

                    // Recent section
                    if (unpinnedNotes.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          icon: Icons.schedule_rounded,
                          label: 'RECENT',
                          color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                        ),
                      ),
                      SliverAlignedGrid.count(
                        crossAxisCount: size.width > 600 ? 3 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: unpinnedNotes.length,
                        itemBuilder: (context, index) {
                          final note = unpinnedNotes[index];
                          return _buildNoteItem(context, theme, isLight, note);
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final note = await ref.read(notesProvider.notifier).createNote();
          if (context.mounted) {
            context.push('/editor/${note.id}');
          }
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}


// ─── Section Header ───────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
