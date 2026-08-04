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
  final int primaryColorValue;

  @HiveField(6)
  final List<String>? stateTags;

  MoodEntry({
    required this.id,
    required this.date,
    this.moodPercentages,
    this.note,
    this.photoPaths,
    int? primaryColorValue,
    int? colorValue,
    this.stateTags,
  }) : primaryColorValue = primaryColorValue ?? colorValue ?? 0xFFFFD700;

  // Backwards compatibility getters for backup service and UI lists
  int get colorValue => primaryColorValue;
  String? get photoPath => (photoPaths != null && photoPaths!.isNotEmpty) ? photoPaths!.first : null;
  List<String> get safePhotoPaths => photoPaths ?? (photoPath != null ? [photoPath!] : []);
}
