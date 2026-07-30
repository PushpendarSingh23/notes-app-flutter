class Note {
  final String id;
  final String userId;
  final String title;
  final String? content;
  final bool isPinned;
  final bool isArchived;
  final bool isFavorite;
  final String colorHex;
  final int version;
  final DateTime updatedAt;
  final String syncStatus;

  const Note({
    required this.id,
    required this.userId,
    required this.title,
    this.content,
    required this.isPinned,
    required this.isArchived,
    this.isFavorite = false,
    required this.colorHex,
    required this.version,
    required this.updatedAt,
    this.syncStatus = 'SYNCED',
  });

  Note copyWith({
    String? title,
    String? content,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    String? colorHex,
    int? version,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Note(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      colorHex: colorHex ?? this.colorHex,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
