import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/mood_entry.dart';

class MoodNotifier extends StateNotifier<List<MoodEntry>> {
  MoodNotifier() : super([]) {
    _loadEntries();
  }

  static const String boxName = 'mood_entries';

  Box<MoodEntry> get _box => Hive.box<MoodEntry>(boxName);

  void _loadEntries() {
    if (Hive.isBoxOpen(boxName)) {
      final entries = _box.values.toList();
      // Sort by newest date first
      entries.sort((a, b) => b.date.compareTo(a.date));
      state = entries;
    }
  }

  Future<void> addEntry(MoodEntry entry) async {
    await _box.put(entry.id, entry);
    _loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    _loadEntries();
  }
}

final moodNotifierProvider =
    StateNotifierProvider<MoodNotifier, List<MoodEntry>>((ref) {
  return MoodNotifier();
});

final hasLoggedTodayProvider = Provider<bool>((ref) {
  final entries = ref.watch(moodNotifierProvider);
  final now = DateTime.now();

  return entries.any((entry) {
    return entry.date.year == now.year &&
        entry.date.month == now.month &&
        entry.date.day == now.day;
  });
});
