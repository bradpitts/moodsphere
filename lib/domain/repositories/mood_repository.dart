import '../models/mood_entry.dart';

/// Abstract contract for local CRUD repository operations for [MoodEntry].
abstract class MoodRepository {
  /// Save a new [MoodEntry] locally.
  Future<void> saveEntry(MoodEntry entry);

  /// Update an existing [MoodEntry] locally.
  Future<void> updateEntry(MoodEntry entry);

  /// Delete a [MoodEntry] by its unique UUID [id], also clearing stored photos.
  Future<void> deleteEntry(String id);

  /// Retrieve a specific [MoodEntry] by [id].
  Future<MoodEntry?> getEntryById(String id);

  /// Query all entries matching a specific [year] and [month] (1-12).
  Future<List<MoodEntry>> getEntriesByMonth(int year, int month);

  /// Retrieve all stored [MoodEntry] items sorted by timestamp descending.
  Future<List<MoodEntry>> getAllEntries();

  /// Save external photo paths to local app storage directory and return local paths.
  Future<List<String>> persistPhotos(List<String> sourcePhotoPaths);
}
