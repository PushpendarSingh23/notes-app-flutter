import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.userId,
    required super.title,
    super.content,
    required super.isPinned,
    required super.isArchived,
    super.isFavorite,
    required super.colorHex,
    required super.version,
    required super.updatedAt,
    super.syncStatus,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json, {String syncStatus = 'SYNCED'}) {
    return NoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      isPinned: _asBool(json['is_pinned']),
      isArchived: _asBool(json['is_archived']),
      isFavorite: _asBool(json['is_favorite']),
      colorHex: json['color_hex'] as String? ?? '#FFFFFF',
      version: json['version'] as int? ?? 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      syncStatus: syncStatus,
    );
  }

  factory NoteModel.fromSqlite(Map<String, dynamic> row) {
    return NoteModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      content: row['content'] as String?,
      isPinned: (row['is_pinned'] as int) == 1,
      isArchived: (row['is_archived'] as int) == 1,
      isFavorite: (row['is_favorite'] as int) == 1,
      colorHex: row['color_hex'] as String? ?? '#FFFFFF',
      version: row['version'] as int? ?? 1,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      syncStatus: row['sync_status'] as String? ?? 'SYNCED',
    );
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'color_hex': colorHex,
      'version': version,
      'created_at': updatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'title': title,
      'content': content,
      'colorHex': colorHex,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'version': version,
    };
  }
}
