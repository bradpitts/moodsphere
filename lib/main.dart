import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/streak_calculator.dart';
import 'data/models/mood_entry_adapter.dart';
import 'data/repositories/mood_repository_impl.dart';
import 'domain/models/mood_entry.dart';
import 'domain/repositories/mood_repository.dart';
import 'widgets/glass_orb_painter_screen.dart';
import 'widgets/home_top_ribbon.dart';
import 'widgets/monthly_insights_view.dart';
import 'widgets/starlight_galaxy_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local offline persistence
  await Hive.initFlutter();

  // Register custom MoodEntryAdapter
  if (!Hive.isAdapterRegistered(AppConstants.moodEntryTypeId)) {
    Hive.registerAdapter(MoodEntryAdapter());
  }

  // Pre-open the Hive box
  await Hive.openBox<MoodEntry>(AppConstants.moodEntriesBoxName);

  final moodRepository = MoodRepositoryImpl();

  runApp(OrbMoodJournalApp(repository: moodRepository));
}

class OrbMoodJournalApp extends StatelessWidget {
  final MoodRepository repository;

  const OrbMoodJournalApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrbMoodJournal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07080E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF161726),
        ),
      ),
      home: JournalDashboardScreen(repository: repository),
    );
  }
}

class JournalDashboardScreen extends StatefulWidget {
  final MoodRepository repository;

  const JournalDashboardScreen({super.key, required this.repository});

  @override
  State<JournalDashboardScreen> createState() => _JournalDashboardScreenState();
}

class _JournalDashboardScreenState extends State<JournalDashboardScreen> {
  List<MoodEntry> _monthEntries = [];
  List<MoodEntry> _allEntries = [];
  bool _isLoading = true;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime _selectedDate = DateTime.now();

  int _activeViewIndex = 0; // 0 = Galaxy 3D, 1 = Journal Cards, 2 = Insights & Calendar

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final monthResults = await widget.repository.getEntriesByMonth(
      _selectedYear,
      _selectedMonth,
    );
    final allResults = await widget.repository.getAllEntries();

    setState(() {
      _monthEntries = monthResults;
      _allEntries = allResults;
      _isLoading = false;
    });
  }

  Future<void> _openGlassOrbPainter() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GlassOrbPainterScreen(repository: widget.repository),
      ),
    );

    if (result == true) {
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Mood Star successfully cast into the 3D Galaxy!'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(String id) async {
    await widget.repository.deleteEntry(id);
    await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final streakCount = StreakCalculator.calculateStreak(_allEntries);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'OrbMoodJournal',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        actions: [
          // Dynamic Fire Streak Badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent, width: 1),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$streakCount Day Streak',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Offline Badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent, width: 1),
            ),
            child: const Icon(
              Icons.offline_pin,
              color: Colors.greenAccent,
              size: 14,
            ),
          ),
        ],
      ),
      body: StarlightGalaxyView(
        entries: _monthEntries,
        child: SafeArea(
          child: Column(
            children: [
              // Top 7-Day Quick Status Ribbon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: HomeTopRibbon(
                  entries: _allEntries,
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      _selectedYear = date.year;
                      _selectedMonth = date.month;
                    });
                    _loadEntries();
                  },
                ),
              ),

              // Navigation Mode Selector Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    _buildTabItem(0, Icons.auto_awesome, '3D Galaxy'),
                    _buildTabItem(1, Icons.view_agenda, 'Journal'),
                    _buildTabItem(2, Icons.calendar_month, 'Insights'),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGlassOrbPainter,
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.palette),
        label: const Text('Paint Glass Orb'),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _activeViewIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeViewIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeViewIndex == 0) {
      // 3D Galaxy View Active: Show 3D hint overlay at bottom
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, color: Color(0xFF8B5CF6), size: 18),
              SizedBox(width: 8),
              Text(
                'Drag to rotate 3D space • Pinch to zoom',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    } else if (_activeViewIndex == 1) {
      // Journal Cards List View
      return _monthEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_classic,
                    size: 54,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No mood stars in ${AppDateUtils.formatMonthYear(_selectedYear, _selectedMonth)}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _monthEntries.length,
              itemBuilder: (context, index) {
                final entry = _monthEntries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: const Color(0xFF161726).withOpacity(0.85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _parseHexColor(entry.dominantColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _parseHexColor(
                                          entry.dominantColor,
                                        ).withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppDateUtils.formatReadable(entry.timestamp),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.white90,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () => _deleteEntry(entry.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.note,
                          style: const TextStyle(
                            color: Colors.white80,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: Text(
                                'Rashi: ${entry.zodiacSign}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: const Color(0xFF24253B),
                            ),
                            ...entry.moodBreakdown.entries.map(
                              (e) => Chip(
                                label: Text(
                                  '${e.key}: ${(e.value * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: const Color(0xFF3B2D54),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
    } else {
      // Monthly Insights & Calendar View
      return MonthlyInsightsView(
        entries: _monthEntries,
        year: _selectedYear,
        month: _selectedMonth,
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
            _activeViewIndex = 1; // Switch to journal list for selected date
          });
        },
      );
    }
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }
}
