import 'package:equatable/equatable.dart';

class Tag extends Equatable {
  final String id;
  final String name;
  final String? color;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    this.color,
    required this.createdAt,
  });

  Tag copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, color, createdAt];
}

class NoteTag extends Equatable {
  final String noteId;
  final String tagId;

  const NoteTag({
    required this.noteId,
    required this.tagId,
  });

  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'tag_id': tagId,
    };
  }

  factory NoteTag.fromMap(Map<String, dynamic> map) {
    return NoteTag(
      noteId: map['note_id'] as String,
      tagId: map['tag_id'] as String,
    );
  }

  @override
  List<Object?> get props => [noteId, tagId];
}
