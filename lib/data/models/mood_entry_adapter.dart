import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/mood_entry.dart';

/// Hive TypeAdapter for binary serialization/deserialization of [MoodEntry].
class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = AppConstants.moodEntryTypeId;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return MoodEntry(
      id: fields[0] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      strokeData: fields[2] as String,
      dominantColor: fields[3] as String,
      moodBreakdown: (fields[4] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ) ??
          {},
      photoPaths: (fields[5] as List?)?.map((e) => e.toString()).toList() ?? [],
      note: fields[6] as String,
      zodiacSign: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp.millisecondsSinceEpoch)
      ..writeByte(2)
      ..write(obj.strokeData)
      ..writeByte(3)
      ..write(obj.dominantColor)
      ..writeByte(4)
      ..write(obj.moodBreakdown)
      ..writeByte(5)
      ..write(obj.photoPaths)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.zodiacSign);
  }
}
