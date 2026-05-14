import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/pattern_model.dart';
import 'utils/app_theme.dart';
import 'screens/analyzer_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/history_screen.dart';
import 'screens/info_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const PatternAnalyzerApp());
}

class PatternAnalyzerApp extends StatelessWidget {
  const PatternAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pattern Strength Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('current_user');
    setState(() {
      _loggedIn = user != null && user.isNotEmpty;
      _checking = false;
    });
  }

  void _onLoginSuccess() {
    setState(() => _loggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (!_loggedIn) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _historyKey = GlobalKey<HistoryScreenState>();

  void _refreshHistory() {
    _historyKey.currentState?.reload();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.weakColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      _AnalyzerWrapper(onHistoryUpdated: _refreshHistory),
      const CompareScreen(),
      HistoryScreen(key: _historyKey),
      InfoScreen(onLogout: _logout),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          indicatorColor: AppTheme.accentGlow,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.lock_outline, color: AppTheme.textHint),
              selectedIcon: Icon(Icons.lock, color: AppTheme.accent),
              label: 'Analyser',
            ),
            NavigationDestination(
              icon: Icon(Icons.compare_arrows, color: AppTheme.textHint),
              selectedIcon: Icon(Icons.compare_arrows, color: AppTheme.accent),
              label: 'Compare',
            ),
            NavigationDestination(
              icon: Icon(Icons.history, color: AppTheme.textHint),
              selectedIcon: Icon(Icons.history, color: AppTheme.accent),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline, color: AppTheme.textHint),
              selectedIcon: Icon(Icons.info, color: AppTheme.accent),
              label: 'About',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Analyzer wrapper ─────────────────────────────────────────────────────────
class _AnalyzerWrapper extends StatefulWidget {
  final VoidCallback? onHistoryUpdated;
  const _AnalyzerWrapper({this.onHistoryUpdated});

  @override
  State<_AnalyzerWrapper> createState() => _AnalyzerWrapperState();
}

class _AnalyzerWrapperState extends State<_AnalyzerWrapper> {
  @override
  Widget build(BuildContext context) {
    return AnalyzerScreen(onAnalysisComplete: _saveToHistory);
  }

  Future<void> _saveToHistory(PatternAnalysisResult result) async {
    final entry = HistoryEntry(
      pattern: result.pattern,
      score: result.compositeScore,
      strength: result.strength,
      timestamp: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('current_user') ?? '';
    final key = user.isEmpty ? 'history' : 'history_$user';
    final existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode(entry.toJson()));
    if (existing.length > 100) {
      existing.removeRange(0, existing.length - 100);
    }
    await prefs.setStringList(key, existing);
    widget.onHistoryUpdated?.call();
  }
}