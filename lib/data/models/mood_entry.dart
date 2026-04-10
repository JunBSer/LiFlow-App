class MoodEntry {
  final int? id;
  final String? remoteId;
  final String emoji;
  final String reason;
  final String category;
  final List<String> keywords;
  final String? imageUrl;
  final DateTime dateTime;

  MoodEntry({
    this.id,
    this.remoteId,
    required this.emoji,
    required this.reason,
    this.category = 'General',
    this.keywords = const [],
    this.imageUrl,
    required this.dateTime,
  });

  MoodEntry copyWith({
    int? id,
    String? remoteId,
    String? emoji,
    String? reason,
    String? category,
    List<String>? keywords,
    String? imageUrl,
    DateTime? dateTime,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      emoji: emoji ?? this.emoji,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      imageUrl: imageUrl ?? this.imageUrl,
      dateTime: dateTime ?? this.dateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remoteId': remoteId,
      'emoji': emoji,
      'reason': reason,
      'category': category,
      'keywords': keywords.join(','),
      'imageUrl': imageUrl,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    final rawKeywords = map['keywords'];

    return MoodEntry(
      id: map['id'],
      remoteId: map['remoteId'],
      emoji: map['emoji'],
      reason: map['reason'],
      category: map['category'] ?? 'General',
      keywords: rawKeywords is String && rawKeywords.isNotEmpty
          ? rawKeywords
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : const [],
      imageUrl: map['imageUrl'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}
