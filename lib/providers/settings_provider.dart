import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/mood_color_preset.dart';

class SettingsState {
  final bool isAppLockEnabled;
  final bool isDailyReminderEnabled;
  final List<MoodColorPreset> customPresets;

  SettingsState({
    required this.isAppLockEnabled,
    required this.isDailyReminderEnabled,
    required this.customPresets,
  });

  SettingsState copyWith({
    bool? isAppLockEnabled,
    bool? isDailyReminderEnabled,
    List<MoodColorPreset>? customPresets,
  }) {
    return SettingsState(
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isDailyReminderEnabled:
          isDailyReminderEnabled ?? this.isDailyReminderEnabled,
      customPresets: customPresets ?? this.customPresets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          isAppLockEnabled: false,
          isDailyReminderEnabled: false,
          customPresets: MoodColorPreset.defaultPresets,
        )) {
    _loadSettings();
  }

  static const String boxName = 'settings_box';
  static const String presetsBoxName = 'mood_color_presets';

  Box get _settingsBox => Hive.box(boxName);
  Box<MoodColorPreset> get _presetsBox => Hive.box<MoodColorPreset>(presetsBoxName);

  void _loadSettings() {
    if (Hive.isBoxOpen(boxName)) {
      final appLock = _settingsBox.get('app_lock', defaultValue: false) as bool;
      final reminder = _settingsBox.get('daily_reminder', defaultValue: false) as bool;
      
      List<MoodColorPreset> presets = [];
      if (Hive.isBoxOpen(presetsBoxName) && _presetsBox.isNotEmpty) {
        presets = _presetsBox.values.toList();
      } else {
        presets = MoodColorPreset.defaultPresets;
      }

      state = SettingsState(
        isAppLockEnabled: appLock,
        isDailyReminderEnabled: reminder,
        customPresets: presets,
      );
    }
  }

  Future<void> toggleAppLock(bool value) async {
    await _settingsBox.put('app_lock', value);
    state = state.copyWith(isAppLockEnabled: value);
  }

  Future<void> toggleDailyReminder(bool value) async {
    await _settingsBox.put('daily_reminder', value);
    state = state.copyWith(isDailyReminderEnabled: value);
  }

  Future<void> addCustomPreset(MoodColorPreset preset) async {
    await _presetsBox.add(preset);
    final updated = _presetsBox.values.toList();
    state = state.copyWith(customPresets: updated);
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
