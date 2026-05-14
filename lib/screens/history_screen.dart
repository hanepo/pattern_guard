import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pattern_model.dart';
import '../utils/app_theme.dart';
import '../utils/pattern_analyzer.dart';
import '../widgets/analysis_result_view.dart';
import '../widgets/node_heatmap.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _history = [];
  bool _loading = true;
  String _currentUser = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void reload() => _loadHistory();

  String _historyKey() =>
      _currentUser.isEmpty ? 'history' : 'history_$_currentUser';

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = prefs.getString('current_user') ?? '';
    final raw = prefs.getStringList(_historyKey()) ?? [];

    // Migrate old global history to user-scoped key on first load
    if (raw.isEmpty && _currentUser.isNotEmpty) {
      final legacy = prefs.getStringList('history') ?? [];
      if (legacy.isNotEmpty) {
        await prefs.setStringList(_historyKey(), legacy);
        setState(() {
          _history = legacy
              .map((s) {
                try { return HistoryEntry.fromJson(jsonDecode(s)); }
                catch (_) { return null; }
              })
              .whereType<HistoryEntry>()
              .toList()
              .reversed
              .toList();
          _loading = false;
        });
        return;
      }
    }

    setState(() {
      _history = raw
          .map((s) {
        try {
          return HistoryEntry.fromJson(jsonDecode(s));
        } catch (_) {
          return null;
        }
      })
          .whereType<HistoryEntry>()
          .toList()
          .reversed
          .toList();

      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear history',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Delete all saved pattern analyses?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.weakColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey());
      setState(() => _history = []);
    }
  }

  Map<int, int> get _nodeFrequency {
    final freq = <int, int>{};

    for (final entry in _history) {
      for (final node in entry.pattern) {
        freq[node] = (freq[node] ?? 0) + 1;
      }
    }

    return freq;
  }

  Map<StrengthCategory, int> get _strengthCounts {
    final counts = {
      for (final category in StrengthCategory.values) category: 0,
    };

    for (final entry in _history) {
      counts[entry.strength] = (counts[entry.strength] ?? 0) + 1;
    }

    return counts;
  }

  static Color categoryColor(StrengthCategory strength) {
    switch (strength) {
      case StrengthCategory.weakest:
        return AppTheme.weakestColor;
      case StrengthCategory.weak:
        return AppTheme.weakColor;
      case StrengthCategory.weakToMedium:
        return AppTheme.weakToMediumColor;
      case StrengthCategory.medium:
        return AppTheme.mediumColor;
      case StrengthCategory.mediumToStrong:
        return AppTheme.mediumToStrongColor;
      case StrengthCategory.strong:
        return AppTheme.strongColor;
      case StrengthCategory.strongest:
        return AppTheme.strongestColor;
    }
  }

  Future<void> _openDetails(HistoryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reveal pattern details?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This page contains sensitive pattern information. Avoid opening it in public.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reveal',
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatternHistoryDetailsScreen(entry: entry),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear history',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      )
          : _history.isEmpty
          ? _buildEmpty()
          : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text(
            'No patterns analysed yet',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'Go to Analyser and draw a pattern',
            style: TextStyle(color: AppTheme.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final counts = _strengthCounts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PrivacyNoticeCard(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: StrengthCategory.values.map((category) {
            final color = categoryColor(category);

            return _StatCard(
              label: category.label,
              value: '${counts[category]}',
              color: color,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _AverageScoreCard(history: _history),
        const SizedBox(height: 16),
        NodeHeatmap(
          nodeFrequency: _nodeFrequency,
          totalPatterns: _history.length,
        ),
        const SizedBox(height: 16),
        Text(
          'RECENT PATTERNS',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 10),
        ..._history.take(20).map(
              (entry) => _HistoryItem(
            entry: entry,
            onReveal: () => _openDetails(entry),
          ),
        ),
      ],
    );
  }
}

class _PrivacyNoticeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.privacy_tip_outlined, color: AppTheme.accent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pattern details are hidden by default. Tap Reveal only when needed.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _AverageScoreCard extends StatelessWidget {
  final List<HistoryEntry> history;

  const _AverageScoreCard({
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox();

    final avg =
        history.map((entry) => entry.score).reduce((a, b) => a + b) /
            history.length;

    final color = avg >= 9.0
        ? AppTheme.strongestColor
        : avg >= 7.5
        ? AppTheme.strongColor
        : avg >= 6.5
        ? AppTheme.mediumToStrongColor
        : avg >= 5.0
        ? AppTheme.mediumColor
        : avg >= 3.5
        ? AppTheme.weakToMediumColor
        : avg >= 1.5
        ? AppTheme.weakColor
        : AppTheme.weakestColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: AppTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Average score across all patterns',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${avg.toStringAsFixed(1)} / 10',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${history.length} total',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onReveal;

  const _HistoryItem({
    required this.entry,
    required this.onReveal,
  });

  Color get _color => HistoryScreenState.categoryColor(entry.strength);

  @override
  Widget build(BuildContext context) {
    final timeAgo = _timeAgo(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _color.withOpacity(0.28)),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: _color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.strength.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: _color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Score: ${entry.score.toStringAsFixed(1)} / 10 • $timeAgo',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Sensitive pattern hidden',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Reveal'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';

    return '${diff.inDays}d ago';
  }
}

class PatternHistoryDetailsScreen extends StatelessWidget {
  final HistoryEntry entry;

  const PatternHistoryDetailsScreen({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final result = PatternAnalyzer.analyze(entry.pattern);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SensitiveWarningCard(),
          const SizedBox(height: 16),
          _PatternPreviewCard(
            pattern: entry.pattern,
            result: result,
          ),
          const SizedBox(height: 16),
          AnalysisResultView(result: result),
        ],
      ),
    );
  }
}

class _SensitiveWarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.riskHigh.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.riskHigh.withOpacity(0.28)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.riskHigh,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sensitive pattern details are visible on this page. Avoid opening this page in public.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPreviewCard extends StatelessWidget {
  final List<int> pattern;
  final PatternAnalysisResult result;

  const _PatternPreviewCard({
    required this.pattern,
    required this.result,
  });

  Color get _color => HistoryScreenState.categoryColor(result.strength);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PATTERN PREVIEW',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textHint,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _color.withOpacity(0.25)),
              ),
              child: _MiniPattern(
                pattern: pattern,
                color: _color,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Node sequence: ${pattern.join(' → ')}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPattern extends StatelessWidget {
  final List<int> pattern;
  final Color color;

  const _MiniPattern({
    required this.pattern,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniPatternPainter(
        pattern: pattern,
        color: color,
      ),
    );
  }
}

class _MiniPatternPainter extends CustomPainter {
  final List<int> pattern;
  final Color color;

  _MiniPatternPainter({
    required this.pattern,
    required this.color,
  });

  Offset _center(int node, Size size) {
    final double cellWidth = size.width / 3;
    final double cellHeight = size.height / 3;

    return Offset(
      cellWidth * (node % 3) + cellWidth / 2,
      cellHeight * (node ~/ 3) + cellHeight / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < pattern.length - 1; i++) {
      canvas.drawLine(
        _center(pattern[i], size),
        _center(pattern[i + 1], size),
        glowPaint,
      );

      canvas.drawLine(
        _center(pattern[i], size),
        _center(pattern[i + 1], size),
        linePaint,
      );
    }

    for (final node in pattern) {
      canvas.drawCircle(
        _center(node, size),
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniPatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.color != color;
  }
}