// GENERATED CODE - MANUAL HIVE ADAPTER IMPLEMENTATION FOR MOODENTRY
part of 'mood_entry.dart';

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 0;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      primaryColorValue: fields[2] as int,
      moodPercentages: (fields[3] as Map).cast<String, double>(),
      stateTags: (fields[4] as List).cast<String>(),
      note: fields[5] as String?,
      photoPaths: (fields[6] as List?)?.cast<String>(),
      strokeDataJson: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.primaryColorValue)
      ..writeByte(3)
      ..write(obj.moodPercentages)
      ..writeByte(4)
      ..write(obj.stateTags)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.photoPaths)
      ..writeByte(7)
      ..write(obj.strokeDataJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
