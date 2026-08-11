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
      moodPercentages: fields[2] as Map?,
      note: fields[3] as String?,
      photoPaths: (fields[4] as List?)?.cast<String>(),
      primaryColorValue: fields[5] as int?,
      stateTags: (fields[6] as List?)?.cast<String>(),
      strokeData: fields[7] as String?,
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
      ..write(obj._moodPercentages)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj._photoPaths)
      ..writeByte(5)
      ..write(obj._primaryColorValue)
      ..writeByte(6)
      ..write(obj._stateTags)
      ..writeByte(7)
      ..write(obj.strokeData);
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
