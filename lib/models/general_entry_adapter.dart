// GENERATED CODE - MANUAL HIVE ADAPTER IMPLEMENTATION FOR GENERALENTRY
part of 'general_entry.dart';

class GeneralEntryAdapter extends TypeAdapter<GeneralEntry> {
  @override
  final int typeId = 2;

  @override
  GeneralEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeneralEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      title: fields[2] as String,
      content: fields[3] as String,
      photoPath: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GeneralEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.photoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneralEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
