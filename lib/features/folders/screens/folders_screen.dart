import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prnote/core/providers/folders_provider.dart';
import 'package:prnote/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + (size.height * 0.02), 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Folders',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.displayLarge?.color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    foldersAsync.when(
                      data: (folders) => Text(
                        '${folders.length} folder${folders.length != 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showCreateFolderDialog(context, ref),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
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

          const SizedBox(height: 12),

          // Folders grid
          Expanded(
            child: foldersAsync.when(
              loading: () => Center(
                child: SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: theme.colorScheme.primary,
                  ),
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 40,
                      color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text('Error loading folders',
                      style: GoogleFonts.inter(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
                  ],
                ),
              ),
              data: (folders) {
                if (folders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: 36,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No folders yet',
                          style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Organize your notes into folders',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final noteCount = ref.watch(folderNoteCountProvider(folder.id));
                    final isDefault = folder.id == AppConstants.defaultFolderId;
                    final folderColor = _getFolderColor(index);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        splashColor: folderColor.withValues(alpha: 0.08),
                        onTap: () {},
                        onLongPress: isDefault
                            ? null
                            : () => _showFolderOptions(context, ref, folder.id, folder.name),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: isLight ? 0.3 : 0.2),
                              width: 0.5,
                            ),
                            boxShadow: isLight
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: folderColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isDefault ? Icons.notes_rounded : Icons.folder_rounded,
                                  color: folderColor,
                                  size: 22,
                                ),
                              ),
                              // Name + count
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.titleMedium?.color,
                                      letterSpacing: -0.1,
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
                                    loading: () => Container(
                                      width: 30, height: 10,
                                      decoration: BoxDecoration(
                                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getFolderColor(int index) {
    const colors = [
      Color(0xFFE5A800), // Amber
      Color(0xFF5C6BC0), // Indigo
      Color(0xFF26A69A), // Teal
      Color(0xFFEF5350), // Red
      Color(0xFF66BB6A), // Green
      Color(0xFFAB47BC), // Purple
      Color(0xFFFF7043), // Orange
      Color(0xFF42A5F5), // Blue
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
        title: Text(
          'New Folder',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(foldersProvider.notifier).createFolder(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(BuildContext context, WidgetRef ref, String folderId, String folderName) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                folderName,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_rounded, size: 20, color: theme.colorScheme.primary),
              ),
              title: Text('Rename', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                _showRenameFolderDialog(context, ref, folderId, folderName);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_rounded, size: 20, color: theme.colorScheme.error),
              ),
              title: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500, color: theme.colorScheme.error),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                ref.read(foldersProvider.notifier).deleteFolder(folderId);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(BuildContext context, WidgetRef ref, String folderId, String currentName) {
    final controller = TextEditingController(text: currentName);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Text('Rename Folder', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(
              color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500)),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(foldersProvider.notifier).renameFolder(folderId, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Rename', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
