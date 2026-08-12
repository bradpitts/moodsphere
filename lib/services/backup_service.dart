import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../models/general_entry.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final moodBox = Hive.box<MoodEntry>('mood_entries');
    final generalBox = Hive.box<GeneralEntry>('general_entries');

    // Serialize entries
    final moodEntriesData = moodBox.values.map((e) => {
          'id': e.id,
          'date': e.date.toIso8601String(),
          'colorValue': e.colorValue,
          'note': e.note,
          'photoPath': e.photoPath,
          'photoPaths': e.safePhotoPaths,
        }).toList();

    final generalEntriesData = generalBox.values.map((e) => {
          'id': e.id,
          'date': e.date.toIso8601String(),
          'title': e.title,
          'content': e.content,
          'photoPath': e.photoPath,
        }).toList();

    final backupPayload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'moodEntries': moodEntriesData,
      'generalEntries': generalEntriesData,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);

    // Prepare Zip Archive
    final encoder = ZipFileEncoder();
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/MoodSphere_Backup_${DateTime.now().millisecondsSinceEpoch}.zip';

    encoder.create(zipPath);

    // Add JSON payload
    final jsonFile = File('${tempDir.path}/backup_data.json');
    await jsonFile.writeAsString(jsonString);
    encoder.addFile(jsonFile);

    // Collect and add photos
    final photoPaths = <String>{};
    for (var e in moodBox.values) {
      for (var p in e.safePhotoPaths) {
        if (File(p).existsSync()) {
          photoPaths.add(p);
        }
      }
    }
    for (var e in generalBox.values) {
      if (e.photoPath != null && File(e.photoPath!).existsSync()) {
        photoPaths.add(e.photoPath!);
      }
    }

    for (var path in photoPaths) {
      final photoFile = File(path);
      encoder.addFile(photoFile);
    }

    encoder.close();

    // Share and cleanup
    await Share.shareXFiles(
      [XFile(zipPath)],
      text: 'MoodSphere Local Backup Archive',
      subject: 'MoodSphere Data Backup',
    );

    // Delete temp file after sharing (it may still be in use, but we can try)
    try {
      await File(zipPath).delete();
    } catch (_) {}
  }
}