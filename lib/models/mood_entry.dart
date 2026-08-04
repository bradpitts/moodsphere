import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 0)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final Map<String, double>? _moodPercentages;

  @HiveField(3)
  final String? note;

  @HiveField(4)
  final List<String>? photoPaths;

  @HiveField(5)
  final int? _primaryColorValue;

  @HiveField(6)
  final List<String>? _stateTags;

  MoodEntry({
    required this.id,
    required this.date,
    Map<String, double>? moodPercentages,
    this.note,
    this.photoPaths,
    int? primaryColorValue,
    int? colorValue,
    List<String>? stateTags,
  })  : _moodPercentages = moodPercentages,
        _primaryColorValue = primaryColorValue ?? colorValue,
        _stateTags = stateTags;

  // Backwards compatibility getters
  int get primaryColorValue => _primaryColorValue ?? 0xFFFFD700;
  int get colorValue => primaryColorValue;

  Map<String, double> get moodPercentages => _moodPercentages ?? {};
  List<String> get stateTags => _stateTags ?? [];

  List<String> get safePhotoPaths => photoPaths ?? (photoPath != null ? [photoPath!] : []);
  String? get photoPath => (photoPaths != null && photoPaths!.isNotEmpty) ? photoPaths!.first : null;
}
