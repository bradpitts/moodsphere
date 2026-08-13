import '../../domain/models/mood_entry.dart';
import '../../domain/repositories/mood_repository.dart';
import '../datasources/mood_local_datasource.dart';
import '../services/image_storage_service.dart';

/// Clean repository implementation fulfilling [MoodRepository] contract.
/// Combines Hive local DataSource with ImageStorageService for offline isolation.
class MoodRepositoryImpl implements MoodRepository {
  final MoodLocalDataSource _localDataSource;
  final ImageStorageService _imageStorageService;

  MoodRepositoryImpl({
    MoodLocalDataSource? localDataSource,
    ImageStorageService? imageStorageService,
  })  : _localDataSource = localDataSource ?? MoodLocalDataSource(),
        _imageStorageService = imageStorageService ?? ImageStorageService();

  @override
  Future<void> saveEntry(MoodEntry entry) async {
    // Persist any photo paths locally in document directory
    final localPhotoPaths = await _imageStorageService.persistPhotos(entry.photoPaths);
    final entryToSave = entry.copyWith(photoPaths: localPhotoPaths);

    await _localDataSource.saveEntry(entryToSave);
  }

  @override
  Future<void> updateEntry(MoodEntry entry) async {
    // Persist photo paths before updating entry
    final localPhotoPaths = await _imageStorageService.persistPhotos(entry.photoPaths);
    final entryToUpdate = entry.copyWith(photoPaths: localPhotoPaths);

    await _localDataSource.saveEntry(entryToUpdate);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final existingEntry = await _localDataSource.getEntryById(id);
    if (existingEntry != null) {
      // Clean up stored image files from local disk
      await _imageStorageService.deletePhotos(existingEntry.photoPaths);
    }
    await _localDataSource.deleteEntry(id);
  }

  @override
  Future<MoodEntry?> getEntryById(String id) {
    return _localDataSource.getEntryById(id);
  }

  @override
  Future<List<MoodEntry>> getEntriesByMonth(int year, int month) {
    return _localDataSource.getEntriesByMonth(year, month);
  }

  @override
  Future<List<MoodEntry>> getAllEntries() {
    return _localDataSource.getAllEntries();
  }

  @override
  Future<List<String>> persistPhotos(List<String> sourcePhotoPaths) {
    return _imageStorageService.persistPhotos(sourcePhotoPaths);
  }
}
