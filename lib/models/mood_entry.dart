import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 0)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int primaryColorValue;

  @HiveField(3)
  final Map<String, double> moodPercentages;

  @HiveField(4)
  final List<String> stateTags;

  @HiveField(5)
  final String? note;

  @HiveField(6)
  final List<String>? photoPaths;

  @HiveField(7)
  final String? strokeDataJson;

  MoodEntry({
    required this.id,
    required this.date,
    required this.primaryColorValue,
    required this.moodPercentages,
    required this.stateTags,
    this.note,
    this.photoPaths,
    this.strokeDataJson,
  });

  MoodEntry copyWith({
    String? id,
    DateTime? date,
    int? primaryColorValue,
    Map<String, double>? moodPercentages,
    List<String>? stateTags,
    String? note,
    List<String>? photoPaths,
    String? strokeDataJson,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      moodPercentages: moodPercentages ?? this.moodPercentages,
      stateTags: stateTags ?? this.stateTags,
      note: note ?? this.note,
      photoPaths: photoPaths ?? this.photoPaths,
      strokeDataJson: strokeDataJson ?? this.strokeDataJson,
    );
  }
}
