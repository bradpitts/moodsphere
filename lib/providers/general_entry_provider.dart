import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/general_entry.dart';

class GeneralEntryNotifier extends StateNotifier<List<GeneralEntry>> {
  GeneralEntryNotifier() : super([]) {
    _loadEntries();
  }

  static const String boxName = 'general_entries';

  Box<GeneralEntry> get _box => Hive.box<GeneralEntry>(boxName);

  void _loadEntries() {
    if (Hive.isBoxOpen(boxName)) {
      final entries = _box.values.toList();
      entries.sort((a, b) => b.date.compareTo(a.date));
      state = entries;
    }
  }

  Future<void> addEntry(GeneralEntry entry) async {
    await _box.put(entry.id, entry);
    _loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    _loadEntries();
  }
}

final generalEntryNotifierProvider =
    StateNotifierProvider<GeneralEntryNotifier, List<GeneralEntry>>((ref) {
  return GeneralEntryNotifier();
});
