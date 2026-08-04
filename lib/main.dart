import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/mood_entry.dart';
import 'models/mood_color_preset.dart';
import 'models/general_entry.dart';
import 'screens/home_screen.dart';
import 'screens/app_lock_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage for local offline data
  await Hive.initFlutter();

  // Register Hive custom/generated adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(MoodEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MoodColorPresetAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(GeneralEntryAdapter());
  }

  // Open required Hive storage boxes
  await Hive.openBox<MoodEntry>('mood_entries');
  await Hive.openBox<MoodColorPreset>('mood_color_presets');
  await Hive.openBox<GeneralEntry>('general_entries');
  final settingsBox = await Hive.openBox('settings_box');

  // Initialize Notification Service
  await NotificationService.init();

  final isAppLockEnabled =
      settingsBox.get('app_lock', defaultValue: false) as bool;

  runApp(
    ProviderScope(
      child: MoodSphereApp(isLocked: isAppLockEnabled),
    ),
  );
}

class MoodSphereApp extends StatefulWidget {
  final bool isLocked;

  const MoodSphereApp({Key? key, required this.isLocked}) : super(key: key);

  @override
  State<MoodSphereApp> createState() => _MoodSphereAppState();
}

class _MoodSphereAppState extends State<MoodSphereApp> {
  late bool _unlocked;

  @override
  void initState() {
    super.initState();
    _unlocked = !widget.isLocked;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodSphere',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFFD700),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          surface: Color(0xFF1E1E2C),
          background: Color(0xFF121212),
          secondary: Color(0xFF2ECC71),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: _unlocked
          ? const HomeScreen()
          : AppLockScreen(
              onUnlocked: () {
                setState(() {
                  _unlocked = true;
                });
              },
            ),
    );
  }
}
