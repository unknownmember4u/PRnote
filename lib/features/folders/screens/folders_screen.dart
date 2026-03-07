import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prnote/core/providers/folders_provider.dart';
import 'package:prnote/core/providers/notes_provider.dart';
import 'package:prnote/models/folder.dart';
import 'package:prnote/models/note.dart';
import 'package:prnote/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final notesAsync = ref.watch(notesProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

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
              data: (allFolders) {
                return notesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(child: Text('Error loading notes')),
                  data: (allNotes) {
                    final folders = allFolders.where((f) => f.parentId == null).toList();
                    final rootNotes = allNotes.where((n) => n.folderId == null && !n.isDeleted).toList();
                    
                    if (folders.isEmpty && rootNotes.isEmpty) {
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
                                Icons.account_tree_rounded,
                                size: 36,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Tree is empty',
                              style: GoogleFonts.inter(
                                fontSize: 17, fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create folders to build your structure',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ...folders.map((folder) => _FolderNode(
                          folder: folder,
                          allFolders: allFolders,
                          allNotes: allNotes,
                          depth: 0,
                          folderColor: _getFolderColor(folders.indexOf(folder)),
                          onLongPress: (ctx, r, id, name) => _showFolderOptions(ctx, r, id, name),
                        )),
                        if (folders.isNotEmpty && rootNotes.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                             child: Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
                           ),
                        ...rootNotes.map((note) => _NoteNode(note: note, depth: 0)),
                      ],
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

// ─── Folder Tree Node ────────────────────────────────────────────────────────

class _FolderNode extends ConsumerStatefulWidget {
  final Folder folder;
  final List<Folder> allFolders;
  final List<Note> allNotes;
  final int depth;
  final Color folderColor;
  final void Function(BuildContext ctx, WidgetRef ref, String id, String name) onLongPress;

  const _FolderNode({
    required this.folder,
    required this.allFolders,
    required this.allNotes,
    required this.depth,
    required this.folderColor,
    required this.onLongPress,
  });

  @override
  ConsumerState<_FolderNode> createState() => _FolderNodeState();
}

class _FolderNodeState extends ConsumerState<_FolderNode> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subFolders = widget.allFolders.where((f) => f.parentId == widget.folder.id).toList();
    final folderNotes = widget.allNotes.where((n) => n.folderId == widget.folder.id && !n.isDeleted).toList();
    
    final hasChildren = subFolders.isNotEmpty || folderNotes.isNotEmpty;
    final isDefault = widget.folder.id == AppConstants.defaultFolderId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (hasChildren) {
                setState(() => _isExpanded = !_isExpanded);
              } else {
                context.push('/folders/${widget.folder.id}');
              }
            },
            onLongPress: isDefault ? null : () => widget.onLongPress(context, ref, widget.folder.id, widget.folder.name),
            child: Padding(
              padding: EdgeInsets.only(
                left: 10.0 + (widget.depth * 20.0),
                right: 12.0,
                top: 8.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  // Expand chevron
                  if (hasChildren)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.transparent,
                        child: Icon(
                          _isExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                          size: 22,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 30),
                  
                  // Folder icon
                  Icon(
                    isDefault ? Icons.notes_rounded : (_isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded),
                    color: widget.folderColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  
                  // Name
                  Expanded(
                    child: Text(
                      widget.folder.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Empty indicator
                  if (!hasChildren)
                     Text(
                       'Empty',
                       style: GoogleFonts.inter(
                         fontSize: 12,
                         color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                       ),
                     ),
                     
                  // Action chevron to full view
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
                    onPressed: () => context.push('/folders/${widget.folder.id}'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Children mapping
        if (_isExpanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...subFolders.map((childFolder) => _FolderNode(
                folder: childFolder,
                allFolders: widget.allFolders,
                allNotes: widget.allNotes,
                depth: widget.depth + 1,
                // Inherited or rotated color
                folderColor: widget.folderColor.withValues(alpha: 0.9),
                onLongPress: widget.onLongPress,
              )),
              ...folderNotes.map((note) => _NoteNode(
                note: note,
                depth: widget.depth + 1,
              )),
            ],
          ),
      ],
    );
  }
}

// ─── Note Tree Node ──────────────────────────────────────────────────────────

class _NoteNode extends StatelessWidget {
  final Note note;
  final int depth;

  const _NoteNode({required this.note, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/editor/${note.id}'),
        child: Padding(
          padding: EdgeInsets.only(
            left: 10.0 + (depth * 20.0) + 30.0,
            right: 16.0,
            top: 10.0, 
            bottom: 10.0,
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 20, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  note.plainTitle.isNotEmpty ? note.plainTitle : 'Untitled',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
