import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/mood_entry.dart';

/// Local DataSource handling raw persistence operations with Hive Box storage.
class MoodLocalDataSource {
  Box<MoodEntry>? _box;

  /// Ensure Hive Box is initialized and open
  Future<Box<MoodEntry>> get _moodBox async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<MoodEntry>(AppConstants.moodEntriesBoxName);
    return _box!;
  }

  /// Save or replace a [MoodEntry] by unique ID
  Future<void> saveEntry(MoodEntry entry) async {
    final box = await _moodBox;
    await box.put(entry.id, entry);
  }

  /// Delete a [MoodEntry] by ID
  Future<void> deleteEntry(String id) async {
    final box = await _moodBox;
    await box.delete(id);
  }

  /// Fetch a single [MoodEntry] by ID
  Future<MoodEntry?> getEntryById(String id) async {
    final box = await _moodBox;
    return box.get(id);
  }

  /// Query all stored entries sorted by timestamp descending
  Future<List<MoodEntry>> getAllEntries() async {
    final box = await _moodBox;
    final entries = box.values.toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  /// Query entries filtered by specific [year] and [month] (1-12)
  Future<List<MoodEntry>> getEntriesByMonth(int year, int month) async {
    final box = await _moodBox;
    final entries = box.values.where((entry) {
      return entry.year == year && entry.month == month;
    }).toList();

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }
}
