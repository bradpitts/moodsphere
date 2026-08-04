import 'package:hive/hive.dart';

part 'general_entry.g.dart';

@HiveType(typeId: 2)
class GeneralEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String? photoPath;

  GeneralEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.photoPath,
  });

  GeneralEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? content,
    String? photoPath,
  }) {
    return GeneralEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
