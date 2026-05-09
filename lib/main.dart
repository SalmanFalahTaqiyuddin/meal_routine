import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav.dart';
import 'package:provider/provider.dart';
import 'providers/schedule_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const MyApp()); // ← runApp di DALAM void main(), sebelum }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleProvider(),
      child: MaterialApp(
        title: 'MealRoutine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const LoginScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String? selectedDay;
  final String? selectedMealType;
  final int initialIndex;

  const MainScreen({
    super.key,
    this.selectedDay,
    this.selectedMealType,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _idx;
  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
  }

  List<Widget> get _screens => [                       // ✅ ubah dari: final _screens = const [...]
    HomeScreen(onGoToOverview: () => setState(() => _idx = 1)),
    OverviewScreen(onGoToHome: () => setState(() => _idx = 0)),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: BottomNav(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}
