import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mood_color_preset.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _presetNameController = TextEditingController();
  int _selectedColorValue = 0xFF9C27B0; // Default Purple

  final List<int> _availableColorValues = [
    0xFF9C27B0, 0xFFE91E63, 0xFFFF9800, 0xFF00BCD4, 0xFF4CAF50, 0xFF3F51B5, 0xFFFF5722, 0xFF607D8B
  ];

  @override
  void dispose() {
    _presetNameController.dispose();
    super.dispose();
  }

  void _showAddPresetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2C),
              title: Text(
                'Add Mood Color Preset',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _presetNameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Preset Name (e.g. Hopeful)',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SELECT COLOR',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableColorValues.map((val) {
                      final color = Color(val);
                      final isSelected = _selectedColorValue == val;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            _selectedColorValue = val;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_presetNameController.text.trim().isNotEmpty) {
                      final newPreset = MoodColorPreset(
                        name: _presetNameController.text.trim(),
                        colorValue: _selectedColorValue,
                      );
                      await ref
                          .read(settingsNotifierProvider.notifier)
                          .addCustomPreset(newPreset);
                      _presetNameController.clear();
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Add Preset',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings & Security',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            // Security Section
            _buildSectionHeader('SECURITY & PRIVACY'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: SwitchListTile(
                value: settings.isAppLockEnabled,
                activeColor: const Color(0xFFFFD700),
                onChanged: (val) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .toggleAppLock(val);
                },
                title: Text(
                  'Biometric / PIN App Lock',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Require authentication when opening MoodSphere',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                ),
                secondary: const Icon(Icons.security, color: Color(0xFFFFD700)),
              ),
            ),

            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionHeader('REMINDERS'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: SwitchListTile(
                value: settings.isDailyReminderEnabled,
                activeColor: const Color(0xFFFFD700),
                onChanged: (val) async {
                  await ref
                      .read(settingsNotifierProvider.notifier)
                      .toggleDailyReminder(val);
                  await NotificationService.scheduleDailyReminder(val);
                },
                title: Text(
                  'Daily Evening Reminder',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Local notification asking you to paint your daily mood orb',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                ),
                secondary: const Icon(Icons.notifications_active_outlined,
                    color: Color(0xFFFFD700)),
              ),
            ),

            const SizedBox(height: 24),

            // Custom Presets Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('COLOR PRESETS'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Color(0xFFFFD700)),
                  onPressed: _showAddPresetDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: settings.customPresets.map((preset) {
                  final color = Color(preset.colorValue);
                  return Chip(
                    avatar: CircleAvatar(backgroundColor: color, radius: 10),
                    label: Text(
                      preset.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: const Color(0xFF121212),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Local Export & Backup Section
            _buildSectionHeader('DATA BACKUP & PORTABILITY'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Complete Local Backup',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bundle all your Hive mood logs, journal entries, and photo attachments into a single offline .ZIP archive file.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await BackupService.exportBackup();
                      },
                      icon: const Icon(Icons.archive_outlined,
                          color: Color(0xFFFFD700)),
                      label: Text(
                        'Export .ZIP Backup Archive',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}
