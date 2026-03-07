import 'package:equatable/equatable.dart';

class NoteVersion extends Equatable {
  final String id;
  final String noteId;
  final String title;
  final String content;
  final int versionNumber;
  final DateTime createdAt;

  const NoteVersion({
    required this.id,
    required this.noteId,
    required this.title,
    required this.content,
    required this.versionNumber,
    required this.createdAt,
  });

  String get plainContent {
    final idx = content.indexOf('\u200B\u200B\u200BCOLOR_SPANS:');
    return idx != -1 ? content.substring(0, idx) : content;
  }

  String get plainTitle {
    final idx = title.indexOf('\u200B\u200B\u200BCOLOR_SPANS:');
    return idx != -1 ? title.substring(0, idx) : title;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'title': title,
      'content': content,
      'version_number': versionNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NoteVersion.fromMap(Map<String, dynamic> map) {
    return NoteVersion(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      versionNumber: map['version_number'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, noteId, title, content, versionNumber, createdAt];
}
