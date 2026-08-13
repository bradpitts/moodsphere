import 'dart:convert';

/// Domain model representing a single mood entry in OrbMoodJournal.
/// 
/// Contains canvas vector stroke data, dominant color, detailed mood breakdown,
/// local photo persistence paths, notes, and zodiac sign metadata.
class MoodEntry {
  final String id;
  final DateTime timestamp;
  final String strokeData; // JSON string of canvas vectors
  final String dominantColor; // Hex string e.g., "#FF5733"
  final Map<String, double> moodBreakdown; // e.g., {"joy": 0.8, "calm": 0.5}
  final List<String> photoPaths; // Local persistent file paths inside app docs
  final String note;
  final String zodiacSign;

  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.strokeData,
    required this.dominantColor,
    required this.moodBreakdown,
    required this.photoPaths,
    required this.note,
    required this.zodiacSign,
  });

  /// Year of entry creation for indexing
  int get year => timestamp.year;

  /// Month of entry creation for indexing (1-12)
  int get month => timestamp.month;

  /// Parsed representation of canvas vectors from JSON strokeData
  List<dynamic> get strokeVectors {
    if (strokeData.isEmpty) return [];
    try {
      final decoded = jsonDecode(strokeData);
      if (decoded is List) return decoded;
    } catch (_) {}
    return [];
  }

  /// Create a copy of MoodEntry with updated fields
  MoodEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? strokeData,
    String? dominantColor,
    Map<String, double>? moodBreakdown,
    List<String>? photoPaths,
    String? note,
    String? zodiacSign,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      strokeData: strokeData ?? this.strokeData,
      dominantColor: dominantColor ?? this.dominantColor,
      moodBreakdown: moodBreakdown ?? Map<String, double>.from(this.moodBreakdown),
      photoPaths: photoPaths ?? List<String>.from(this.photoPaths),
      note: note ?? this.note,
      zodiacSign: zodiacSign ?? this.zodiacSign,
    );
  }

  /// Convert MoodEntry to Map structure
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'strokeData': strokeData,
      'dominantColor': dominantColor,
      'moodBreakdown': moodBreakdown,
      'photoPaths': photoPaths,
      'note': note,
      'zodiacSign': zodiacSign,
    };
  }

  /// Factory constructor to construct MoodEntry from Map structure
  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      strokeData: map['strokeData'] as String? ?? '[]',
      dominantColor: map['dominantColor'] as String? ?? '#6200EE',
      moodBreakdown: (map['moodBreakdown'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ) ??
          {},
      photoPaths: (map['photoPaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      note: map['note'] as String? ?? '',
      zodiacSign: map['zodiacSign'] as String? ?? 'Unknown',
    );
  }

  /// Serialize to JSON string
  String toJson() => jsonEncode(toMap());

  /// Deserialize from JSON string
  factory MoodEntry.fromJson(String source) =>
      MoodEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MoodEntry(id: $id, timestamp: $timestamp, dominantColor: $dominantColor, zodiacSign: $zodiacSign)';
  }
}
