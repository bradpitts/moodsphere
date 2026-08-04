import 'package:hive/hive.dart';

part 'mood_color_preset.g.dart';

@HiveType(typeId: 1)
class MoodColorPreset extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int colorValue;

  MoodColorPreset({
    required this.name,
    required this.colorValue,
  });

  static List<MoodColorPreset> defaultPresets = [
    MoodColorPreset(name: 'Joy', colorValue: 0xFFFFD700),       // Radiant Gold
    MoodColorPreset(name: 'Calm', colorValue: 0xFF2ECC71),      // Emerald Green
    MoodColorPreset(name: 'Serene', colorValue: 0xFF3498DB),    // Azure Blue
    MoodColorPreset(name: 'Energy', colorValue: 0xFFE74C3C),    // Vibrant Red
    MoodColorPreset(name: 'Creative', colorValue: 0xFF9B59B6),  // Deep Violet
    MoodColorPreset(name: 'Passion', colorValue: 0xFFFF6B6B),   // Coral Pink
    MoodColorPreset(name: 'Melancholy', colorValue: 0xFF5D6D7E),// Slate Grey
    MoodColorPreset(name: 'Peace', colorValue: 0xFF1ABC9C),     // Turquoise
  ];
}
