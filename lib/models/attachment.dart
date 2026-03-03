import 'package:equatable/equatable.dart';

enum AttachmentType { image, audio, video, file }

class Attachment extends Equatable {
  final String id;
  final String noteId;
  final String fileName;
  final String filePath;
  final AttachmentType type;
  final int fileSize;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.fileSize,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'file_name': fileName,
      'file_path': filePath,
      'type': type.name,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      type: AttachmentType.values.byName(map['type'] as String),
      fileSize: map['file_size'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, noteId, fileName, filePath, type, fileSize, createdAt];
}
