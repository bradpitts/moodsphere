import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_entry.dart';

final moodNotifierProvider = StateNotifierProvider<MoodEntriesNotifier, List<MoodEntry>>((ref) {
  return MoodEntriesNotifier();
});

// Alias to prevent naming mismatch errors
final moodEntriesProvider = moodNotifierProvider;

class MoodEntriesNotifier extends StateNotifier<List<MoodEntry>> {
  MoodEntriesNotifier() : super([]) {
    loadEntries();
  }

  final Box<MoodEntry> _box = Hive.box<MoodEntry>('mood_entries');

  void loadEntries() {
    state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addEntry(MoodEntry entry) async {
    await _box.put(entry.id, entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    loadEntries();
  }
}

final hasLoggedTodayProvider = Provider<bool>((ref) {
  final entries = ref.watch(moodNotifierProvider);
  if (entries.isEmpty) return false;
  
  final latestDate = entries.first.date;
  final now = DateTime.now();
  return latestDate.year == now.year &&
         latestDate.month == now.month &&
         latestDate.day == now.day;
});
