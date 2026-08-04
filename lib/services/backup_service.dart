import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/mood_entry.dart';

class BackupService {
  static Future<File?> createZipBackup() async {
    try {
      final archive = Archive();
      final moodBox = Hive.box<MoodEntry>('mood_entries');
      final entries = moodBox.values.toList();

      final List<Map<String, dynamic>> jsonEntries = entries.map((e) {
        return {
          'id': e.id,
          'date': e.date.toIso8601String(),
          'primaryColorValue': e.primaryColorValue,
          'colorValue': e.colorValue,
          'moodPercentages': e.moodPercentages,
          'stateTags': e.stateTags,
          'note': e.note,
          'photoPaths': e.safePhotoPaths,
          'photoPath': e.photoPath,
        };
      }).toList();

      final jsonString = jsonEncode(jsonEntries);
      archive.addFile(ArchiveFile('entries.json', jsonString.length, utf8.encode(jsonString)));

      for (var e in entries) {
        for (var path in e.safePhotoPaths) {
          final file = File(path);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            final fileName = path.split('/').last;
            archive.addFile(ArchiveFile('photos/$fileName', bytes.length, bytes));
          }
        }
      }

      final zipEncoder = ZipEncoder();
      final encodedArchive = zipEncoder.encode(archive);
      if (encodedArchive == null) return null;

      final tempDir = await getTemporaryDirectory();
      final zipFile = File('${tempDir.path}/MoodSphere_Backup_${DateTime.now().millisecondsSinceEpoch}.zip');
      await zipFile.writeAsBytes(encodedArchive);

      return zipFile;
    } catch (e) {
      return null;
    }
  }

  static Future<void> exportBackup() async {
    final file = await createZipBackup();
    if (file != null && file.existsSync()) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MoodSphere Local Backup',
        text: 'Here is your local MoodSphere backup zip file.',
      );
    }
  }
}
