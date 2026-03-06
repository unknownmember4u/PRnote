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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + (size.height * 0.02), 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                color: const Color(0xFFFFC107),
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
                          // Search icon button
                          GestureDetector(
                            onTap: () => SearchOverlay.show(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.dividerColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                size: 22,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Date badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(height: 4),
                  Text(
                    'All Notes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notes list
          notesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Something went wrong', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.read(notesProvider.notifier).loadNotes(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (notes) {
              if (notes.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(),
                );
              }

              final pinnedNotes = notes.where((n) => n.isPinned).toList();
              final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Pinned section
                    if (pinnedNotes.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PINNED',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...pinnedNotes.map((note) => NoteCard(
                            note: note,
                            onTap: () => context.push('/editor/${note.id}'),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Recent section
                    if (unpinnedNotes.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                        child: Text(
                          'RECENT',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodySmall?.color,
                            letterSpacing: 1.5,
                          ),
                        ),
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
