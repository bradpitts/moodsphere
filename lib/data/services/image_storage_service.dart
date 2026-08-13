import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

/// Local image persistence service that copies gallery/camera images into
/// the application's document directory for offline persistence.
class ImageStorageService {
  final Uuid _uuid = const Uuid();
  Directory? _photoDir;

  /// Initialize and prepare local storage folder inside App Document Directory
  Future<Directory> get photoDirectory async {
    if (_photoDir != null && await _photoDir!.exists()) {
      return _photoDir!;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final photoDirPath = p.join(appDocDir.path, AppConstants.imageStorageSubdir);
    _photoDir = Directory(photoDirPath);
    if (!await _photoDir!.exists()) {
      await _photoDir!.create(recursive: true);
    }
    return _photoDir!;
  }

  /// Copies a single photo from [sourcePath] into application local directory
  /// and returns the absolute path of the persistent stored image.
  Future<String> persistPhoto(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source image does not exist', sourcePath);
    }

    final targetDir = await photoDirectory;
    final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final uniqueFileName = 'img_${_uuid.v4()}$extension';
    final targetPath = p.join(targetDir.path, uniqueFileName);

    final copiedFile = await sourceFile.copy(targetPath);
    return copiedFile.path;
  }

  /// Copies a list of photo source paths into application local directory
  Future<List<String>> persistPhotos(List<String> sourcePaths) async {
    final List<String> persistentPaths = [];
    for (final path in sourcePaths) {
      if (path.trim().isEmpty) continue;
      // If path is already inside local photo directory, retain it
      final targetDir = await photoDirectory;
      if (p.isWithin(targetDir.path, path)) {
        persistentPaths.add(path);
        continue;
      }
      final savedPath = await persistPhoto(path);
      persistentPaths.add(savedPath);
    }
    return persistentPaths;
  }

  /// Delete photos from local disk when associated entry is removed
  Future<void> deletePhotos(List<String> filePaths) async {
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }
}
