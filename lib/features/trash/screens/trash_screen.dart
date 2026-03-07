import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:prnote/core/providers/notes_provider.dart';
import 'package:prnote/features/home/widgets/note_card.dart';
import 'package:prnote/models/note.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
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

  void _selectAll(List<Note> notes) {
    setState(() {
      _selectedNotes.addAll(notes.map((n) => n.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNotes.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final trashNotesAsync = ref.watch(trashNotesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
        title: Text(
          _isSelectionMode ? '${_selectedNotes.length} Selected' : 'Trash',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.displayLarge?.color,
          ),
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.restore_page_rounded),
              tooltip: 'Restore Selected',
              onPressed: () async {
                await ref.read(notesProvider.notifier).restoreMultiple(_selectedNotes.toList());
                _clearSelection();
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
              tooltip: 'Delete Permanently',
              onPressed: () async {
                await ref.read(notesProvider.notifier).permanentlyDeleteMultiple(_selectedNotes.toList());
                _clearSelection();
              },
            ),
          ] else if (trashNotesAsync is AsyncData && (trashNotesAsync.value ?? []).isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              tooltip: 'Select All',
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                  _selectAll(trashNotesAsync.value!);
                });
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: trashNotesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 64,
                    color: theme.dividerColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trash is empty',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          return MasonryGridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: notes.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final note = notes[index];
              final isSelected = _selectedNotes.contains(note.id);

              return Stack(
                children: [
                  NoteCard(
                    note: note,
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(note.id);
                      } else {
                        // Open a simple preview or default to selection
                        setState(() {
                          _isSelectionMode = true;
                          _toggleSelection(note.id);
                        });
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      }
                      _toggleSelection(note.id);
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
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
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
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
