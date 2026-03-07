import 'package:flutter/material.dart';
import 'package:prnote/models/note.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final preview = note.plainContent.trim();
    final timeAgo = _formatTimeAgo(note.updatedAt);

    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: note.color != null
                  ? Color(int.parse(note.color!.replaceFirst('#', '0xFF'))).withValues(alpha: 0.06)
                  : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: isLight ? 0.35 : 0.2),
                width: 0.5,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Pin indicator
                    if (note.isPinned) ...[
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    // Title
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: note.title.isEmpty
                              ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)
                              : theme.textTheme.titleLarge?.color,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isFavorite) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: const Color(0xFFFFB300),
                      ),
                    ],
                  ],
                ),

                // Preview
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    preview,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Footer: time + folder
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Time
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Chevron hint
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}
