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

final moodEntriesProvider = moodNotifierProvider;

final hasLoggedTodayProvider = Provider<bool>((ref) {
  final entries = ref.watch(moodNotifierProvider);
  final now = DateTime.now();

  return entries.any((entry) {
    return entry.date.year == now.year &&
        entry.date.month == now.month &&
        entry.date.day == now.day;
  });
});

final currentStreakProvider = Provider<int>((ref) {
  final entries = ref.watch(moodNotifierProvider);
  if (entries.isEmpty) return 0;

  final uniqueDates = entries
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (!uniqueDates.contains(today) && !uniqueDates.contains(yesterday)) {
    return 0;
  }

  int streak = 0;
  DateTime checkDate = uniqueDates.contains(today) ? today : yesterday;

  while (uniqueDates.contains(checkDate)) {
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
  }

  return streak;
});
