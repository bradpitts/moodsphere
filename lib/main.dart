import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'models/mood_entry.dart';
import 'models/mood_color_preset.dart';
import 'models/general_entry.dart';
import 'screens/home_screen.dart';
import 'screens/app_lock_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MoodEntryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MoodColorPresetAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GeneralEntryAdapter());

  await Hive.openBox<MoodEntry>('mood_entries');
  await Hive.openBox<MoodColorPreset>('mood_color_presets');
  await Hive.openBox<GeneralEntry>('general_entries');
  final settingsBox = await Hive.openBox('settings_box');

  await NotificationService.init();

  final isAppLockEnabled = settingsBox.get('app_lock', defaultValue: false) as bool;

  runApp(
    ProviderScope(
      child: SplashScreenWrapper(isLocked: isAppLockEnabled),
    ),
  );
}

class SplashScreenWrapper extends StatefulWidget {
  final bool isLocked;
  const SplashScreenWrapper({Key? key, required this.isLocked}) : super(key: key);

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
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
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: _showSplash 
          ? const SplashScreen() 
          : MoodSphereApp(isLocked: widget.isLocked),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [Color(0xFFFFD700), Color(0xFF50E3C2), Color(0xFFFFD700)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MoodSphere',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(
              'Made by Vignesh',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class MoodSphereApp extends StatefulWidget {
  final bool isLocked;
  const MoodSphereApp({Key? key, required this.isLocked}) : super(key: key);

  @override
  State<MoodSphereApp> createState() => _MoodSphereAppState();
}

class _MoodSphereAppState extends State<MoodSphereApp> with WidgetsBindingObserver {
  late bool _unlocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlocked = !widget.isLocked;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

 @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) && widget.isLocked) {
    setState(() { _unlocked = false; });
  }
}

  @override
  Widget build(BuildContext context) {
    return _unlocked
        ? const HomeScreen()
        : AppLockScreen(onUnlocked: () => setState(() => _unlocked = true));
  }

}