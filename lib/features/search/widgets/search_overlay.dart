import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prnote/core/providers/notes_provider.dart';
import 'package:prnote/models/note.dart';
import 'package:google_fonts/google_fonts.dart';

/// A full-screen search overlay with debounced input,
/// highlighted result snippets, and smooth animations.
class SearchOverlay extends ConsumerStatefulWidget {
  const SearchOverlay({super.key});

  /// Show the search overlay as a full-screen modal
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SearchOverlay();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.03),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
    );
  }

  @override
  ConsumerState<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<SearchOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    if (mounted && _hasFocus != _focusNode.hasFocus) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
  }

  void _onQueryChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    // Only rebuild for clear button visibility toggle
    if ((value.isEmpty) != (_controller.text.isEmpty)) {
      setState(() {});
    }
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
    _focusNode.requestFocus();
  }

  void _close() {
    ref.read(searchQueryProvider.notifier).state = '';
    Navigator.of(context).pop();
  }

  void _openNote(String noteId) {
    ref.read(searchQueryProvider.notifier).state = '';
    Navigator.of(context).pop();
    context.push('/editor/$noteId');
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSearchBar(theme, topPadding),
          Expanded(
            child: query.isEmpty
                ? _buildIdleState(theme)
                : _buildResults(theme, searchResults, query),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────
  Widget _buildSearchBar(ThemeData theme, double topPadding) {
    final borderColor = _hasFocus
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : theme.dividerColor.withValues(alpha: 0.3);

    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 10, 12, 10),
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
          // Close
          IconButton(
            onPressed: _close,
            splashRadius: 22,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.textTheme.titleMedium?.color,
              size: 23,
            ),
          ),

          // Input field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: _hasFocus ? 1.5 : 1),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.search_rounded,
                      color: _hasFocus
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                      size: 21,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          splashRadius: 18,
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: theme.textTheme.bodySmall?.color,
                              size: 16,
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Idle State (no query) ────────────────────────────
  Widget _buildIdleState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 36,
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Search your notes',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Find by title or content',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Results ──────────────────────────────────────────
  Widget _buildResults(
    ThemeData theme,
    AsyncValue<List<Note>> searchResults,
    String query,
  ) {
    return searchResults.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
      error: (e, _) => _buildErrorState(theme),
      data: (notes) {
        if (notes.isEmpty) return _buildNoResults(theme, query);
        return _buildResultsList(theme, notes, query);
      },
    );
  }

  Widget _buildResultsList(ThemeData theme, List<Note> notes, String query) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: notes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
            child: Text(
              '${notes.length} result${notes.length != 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                letterSpacing: 0.3,
              ),
            ),
          );
        }

        final note = notes[index - 1];
        return _SearchResultCard(
          note: note,
          query: query,
          theme: theme,
          onTap: () => _openNote(note.id),
        );
      },
    );
  }

  Widget _buildNoResults(ThemeData theme, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 32,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No results for "$query"',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try different keywords',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Search failed',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SEARCH RESULT CARD — lightweight card with highlighted text
// ═══════════════════════════════════════════════════════════

class _SearchResultCard extends StatelessWidget {
  final Note note;
  final String query;
  final ThemeData theme;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.note,
    required this.query,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final snippet = _getSnippet(note.content, query, 80);
    final hasContent = snippet.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with highlight
                _HighlightedText(
                  text: note.title.isNotEmpty ? note.title : 'Untitled',
                  query: query,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: note.title.isNotEmpty
                        ? theme.textTheme.titleMedium?.color
                        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                  highlightColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),

                if (hasContent) ...[
                  const SizedBox(height: 6),
                  // Content snippet with highlight
                  _HighlightedText(
                    text: snippet,
                    query: query,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                    highlightColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    maxLines: 2,
                  ),
                ],

                const SizedBox(height: 8),
                // Metadata row
                Row(
                  children: [
                    if (note.isPinned) ...[
                      Icon(
                        Icons.push_pin_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (note.isFavorite) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatDate(note.updatedAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Extract a snippet around the first match of the query
  String _getSnippet(String content, String query, int radius) {
    if (content.isEmpty || query.isEmpty) return content;
    final lower = content.toLowerCase();
    final qLower = query.toLowerCase();
    final matchIndex = lower.indexOf(qLower);

    if (matchIndex == -1) {
      // No match in content — show start
      return content.length > radius * 2
          ? '${content.substring(0, radius * 2).trim()}…'
          : content;
    }

    final start = (matchIndex - radius).clamp(0, content.length);
    final end = (matchIndex + query.length + radius).clamp(0, content.length);
    var snippet = content.substring(start, end).replaceAll('\n', ' ').trim();

    if (start > 0) snippet = '…$snippet';
    if (end < content.length) snippet = '$snippet…';
    return snippet;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════
// HIGHLIGHTED TEXT — paints matching query substring
// ═══════════════════════════════════════════════════════════

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final Color highlightColor;
  final int maxLines;

  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
    required this.highlightColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    int pos = 0;

    while (pos < text.length) {
      final matchIndex = lower.indexOf(qLower, pos);
      if (matchIndex == -1) {
        spans.add(TextSpan(text: text.substring(pos)));
        break;
      }

      // Text before match
      if (matchIndex > pos) {
        spans.add(TextSpan(text: text.substring(pos, matchIndex)));
      }

      // Highlighted match
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query.length),
        style: TextStyle(
          backgroundColor: highlightColor,
          fontWeight: FontWeight.w700,
        ),
      ));

      pos = matchIndex + query.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
