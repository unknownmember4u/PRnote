import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prnote/core/providers/notes_provider.dart';
import 'package:prnote/features/home/widgets/note_card.dart';
import 'package:prnote/features/home/widgets/empty_state.dart';
import 'package:prnote/features/search/widgets/search_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
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
                  // Top row: Logo + actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'PR',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            TextSpan(
                              text: 'note',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                color: theme.textTheme.displayLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Search icon
                          _ActionButton(
                            icon: Icons.search_rounded,
                            onTap: () => SearchOverlay.show(context),
                            theme: theme,
                            isLight: isLight,
                          ),
                          const SizedBox(width: 8),
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
                    ],
                  ),

                  const SizedBox(height: 12),

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
                ],
              ),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 0.5,
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),

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
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Pinned section
                    if (pinnedNotes.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.push_pin_rounded,
                        label: 'PINNED',
                        color: theme.colorScheme.primary,
                      ),
                      ...pinnedNotes.map((note) => NoteCard(
                        note: note,
                        onTap: () => context.push('/editor/${note.id}'),
                      )),
                      const SizedBox(height: 20),
                    ],

                    // Recent section
                    if (unpinnedNotes.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.schedule_rounded,
                        label: 'RECENT',
                        color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                      ),
                      ...unpinnedNotes.map((note) => NoteCard(
                        note: note,
                        onTap: () => context.push('/editor/${note.id}'),
                      )),
                    ],
                  ]),
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

// ─── Action Button ────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isLight;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.theme,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 21, color: theme.textTheme.bodyMedium?.color),
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
