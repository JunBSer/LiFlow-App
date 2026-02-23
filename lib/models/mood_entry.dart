class MoodEntry {
  final int? id;
  final String emoji;
  final String reason;
  final DateTime dateTime;

  MoodEntry({
    this.id,
    required this.emoji,
    required this.reason,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emoji': emoji,
      'reason': reason,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      emoji: map['emoji'],
      reason: map['reason'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}