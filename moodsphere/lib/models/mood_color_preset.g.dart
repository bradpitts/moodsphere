// GENERATED CODE - MANUAL HIVE ADAPTER IMPLEMENTATION FOR MOODCOLORPRESET
part of 'mood_color_preset.dart';

class MoodColorPresetAdapter extends TypeAdapter<MoodColorPreset> {
  @override
  final int typeId = 1;

  @override
  MoodColorPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodColorPreset(
      name: fields[0] as String,
      colorValue: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MoodColorPreset obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodColorPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
