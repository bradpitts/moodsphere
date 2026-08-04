import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 0)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final String? note;

  @HiveField(4)
  final String? photoPath;

  MoodEntry({
    required this.id,
    required this.date,
    required this.colorValue,
    this.note,
    this.photoPath,
  });

  MoodEntry copyWith({
    String? id,
    DateTime? date,
    int? colorValue,
    String? note,
    String? photoPath,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      colorValue: colorValue ?? this.colorValue,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
