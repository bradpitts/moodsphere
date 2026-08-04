import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 0)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final Map<String, double>? moodPercentages;

  @HiveField(3)
  final String? note;

  @HiveField(4)
  final List<String>? photoPaths;

  @HiveField(5)
  final int? primaryColorValue;

  @HiveField(6)
  final List<String>? stateTags;

  MoodEntry({
    required this.id,
    required this.date,
    this.moodPercentages,
    this.note,
    this.photoPaths,
    this.primaryColorValue,
    this.stateTags,
  });

  // Backwards compatibility getters for services & list views
  int get colorValue => primaryColorValue ?? (moodPercentages?.values.isNotEmpty == true ? 0xFFFFD700 : 0xFFFFD700);
  String? get photoPath => (photoPaths != null && photoPaths!.isNotEmpty) ? photoPaths!.first : null;
}
