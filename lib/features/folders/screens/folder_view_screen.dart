import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prnote/core/providers/folders_provider.dart';
import 'package:prnote/core/providers/notes_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prnote/features/home/widgets/note_card.dart';

class FolderViewScreen extends ConsumerWidget {
  final String folderId;

  const FolderViewScreen({super.key, required this.folderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final isLight = theme.brightness == Brightness.light;

    final foldersAsync = ref.watch(foldersProvider);
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(8, topPadding + (size.height * 0.01), 20, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: foldersAsync.when(
                    data: (folders) {
                      final folder = folders.firstWhere((f) => f.id == folderId, orElse: () => folders.first);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.displayLarge?.color,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showCreateFolderDialog(context, ref),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.create_new_folder_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 0.5,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
          
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                // Sub-folders Section
                SliverToBoxAdapter(
                  child: foldersAsync.when(
                    data: (allFolders) {
                      final subFolders = allFolders.where((f) => f.parentId == folderId).toList();
                      if (subFolders.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Text(
                              'Subfolders',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: subFolders.length,
                            itemBuilder: (context, index) {
                              final folder = subFolders[index];
                              final noteCount = ref.watch(folderNoteCountProvider(folder.id));
                              final folderColor = _getFolderColor(index);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  splashColor: folderColor.withValues(alpha: 0.08),
                                  onTap: () => context.push('/folders/${folder.id}'),
                                  onLongPress: () => _showFolderOptions(context, ref, folder.id, folder.name),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.cardTheme.color,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: theme.dividerColor.withValues(alpha: isLight ? 0.3 : 0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: folderColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.folder_shared_rounded,
                                            color: folderColor,
                                            size: 22,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              folder.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textTheme.titleMedium?.color,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            noteCount.when(
                                              data: (count) => Text(
                                                '$count note${count != 1 ? 's' : ''}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
                                                ),
                                              ),
                                              loading: () => const SizedBox.shrink(),
                                              error: (_, __) => const SizedBox(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // Notes Section
                SliverToBoxAdapter(
                  child: notesAsync.when(
                    data: (allNotes) {
                      final folderNotes = allNotes.where((n) => n.folderId == folderId && !n.isDeleted).toList();
                      if (folderNotes.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_add_rounded, size: 48,
                                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  'Folder is empty',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Text(
                              'Notes',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: folderNotes.length,
                            itemBuilder: (context, index) {
                              final note = folderNotes[index];
                              return NoteCard(
                                note: note,
                                onTap: () => context.push('/editor/${note.id}'),
                              );
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final note = await ref.read(notesProvider.notifier).createNote(folderId: folderId);
          if (context.mounted) {
            context.push('/editor/${note.id}');
          }
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Color _getFolderColor(int index) {
    const colors = [
      Color(0xFFE5A800), Color(0xFF5C6BC0), Color(0xFF26A69A),
      Color(0xFFEF5350), Color(0xFF66BB6A), Color(0xFFAB47BC),
      Color(0xFFFF7043), Color(0xFF42A5F5),
    ];
    return colors[index % colors.length];
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Text('New Subfolder', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(hintText: 'Folder name', hintStyle: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500)),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(foldersProvider.notifier).createFolder(controller.text.trim(), parentId: folderId);
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(BuildContext context, WidgetRef ref, String targetFolderId, String folderName) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(folderName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.delete_rounded, size: 20, color: theme.colorScheme.error)),
              title: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: theme.colorScheme.error)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                ref.read(foldersProvider.notifier).deleteFolder(targetFolderId);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
