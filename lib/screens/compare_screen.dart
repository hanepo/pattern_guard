import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pattern_model.dart';
import '../utils/app_theme.dart';
import '../utils/pattern_analyzer.dart';
import '../widgets/pattern_grid.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen>
    with SingleTickerProviderStateMixin {
  final _grid1Key = GlobalKey<PatternGridState>();
  final _grid2Key = GlobalKey<PatternGridState>();

  PatternAnalysisResult? _result1;
  PatternAnalysisResult? _result2;
  int _activeSlot = 1;
  bool _isDrawingPattern = false;

  late AnimationController _compareAnim;
  late Animation<double> _compareFade;

  @override
  void initState() {
    super.initState();
    _compareAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _compareFade = CurvedAnimation(
      parent: _compareAnim,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _compareAnim.dispose();
    super.dispose();
  }

  void _onComplete1(List<int> pattern) {
    setState(() {
      _result1 = PatternAnalyzer.analyze(pattern);
      _activeSlot = 2;
    });

    HapticFeedback.mediumImpact();

    if (_result2 != null) {
      _compareAnim.forward(from: 0);
    }
  }

  void _onComplete2(List<int> pattern) {
    setState(() {
      _result2 = PatternAnalyzer.analyze(pattern);
    });

    HapticFeedback.mediumImpact();

    if (_result1 != null) {
      _compareAnim.forward(from: 0);
    }
  }

  void _reset() {
    _grid1Key.currentState?.reset();
    _grid2Key.currentState?.reset();

    setState(() {
      _result1 = null;
      _result2 = null;
      _activeSlot = 1;
    });

    _compareAnim.reset();
  }

  String get _instruction {
    if (_result1 == null) return 'Draw Pattern A first.';
    if (_result2 == null) return 'Now draw Pattern B.';
    return 'Both patterns analysed. Review the comparison below.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Patterns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reset,
            tooltip: 'Reset both patterns',
          ),
        ],
      ),
      body: ListView(
        physics: _isDrawingPattern
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _InstructionCard(text: _instruction),
          const SizedBox(height: 16),

          Listener(
            onPointerDown: (_) => setState(() => _isDrawingPattern = true),
            onPointerUp: (_) => setState(() => _isDrawingPattern = false),
            onPointerCancel: (_) => setState(() => _isDrawingPattern = false),
            child: _GridSlot(
              label: 'Pattern A',
              gridKey: _grid1Key,
              result: _result1,
              isActive: _activeSlot == 1 && _result1 == null,
              onComplete: _onComplete1,
              onChanged: (_, __) {},
            ),
          ),

          const SizedBox(height: 16),

          Listener(
            onPointerDown: (_) => setState(() => _isDrawingPattern = true),
            onPointerUp: (_) => setState(() => _isDrawingPattern = false),
            onPointerCancel: (_) => setState(() => _isDrawingPattern = false),
            child: _GridSlot(
              label: 'Pattern B',
              gridKey: _grid2Key,
              result: _result2,
              isActive: _activeSlot == 2 && _result2 == null,
              onComplete: _onComplete2,
              onChanged: (_, __) {},
            ),
          ),

          if (_result1 != null && _result2 != null) ...[
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _compareFade,
              child: _WinnerBanner(r1: _result1!, r2: _result2!),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _compareFade,
              child: _ComparisonTable(r1: _result1!, r2: _result2!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String text;

  const _InstructionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppTheme.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridSlot extends StatelessWidget {
  final String label;
  final GlobalKey<PatternGridState> gridKey;
  final PatternAnalysisResult? result;
  final bool isActive;
  final Function(List<int>) onComplete;
  final Function(List<int>, PatternAnalysisResult?) onChanged;

  const _GridSlot({
    required this.label,
    required this.gridKey,
    required this.result,
    required this.isActive,
    required this.onComplete,
    required this.onChanged,
  });

  Color get _color {
    if (result == null) return isActive ? AppTheme.accent : AppTheme.border;

    switch (result!.strength) {
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

  String get _statusText {
    if (result != null) return result!.strength.label;
    if (isActive) return 'Draw now';
    return 'Waiting';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _color.withOpacity(isActive ? 0.75 : 0.25),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(isActive ? 0.12 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _color.withOpacity(0.35)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              if (result != null)
                Text(
                  '${result!.compositeScore.toStringAsFixed(0)}/10',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _color,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 220,
            child: PatternGrid(
              key: gridKey,
              onPatternChanged: onChanged,
              onPatternComplete: onComplete,
              isEnabled: isActive || result == null,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                result == null
                    ? Icons.touch_app_rounded
                    : Icons.check_circle_rounded,
                color: _color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: _color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final PatternAnalysisResult r1;
  final PatternAnalysisResult r2;

  const _ComparisonTable({
    required this.r1,
    required this.r2,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      _RowData('Score', r1.compositeScore, r2.compositeScore,
          higherIsBetter: true),
      _RowData('Nodes', r1.nodeCount.toDouble(), r2.nodeCount.toDouble(),
          higherIsBetter: true),
      _RowData('Length', r1.physicalLength, r2.physicalLength,
          higherIsBetter: true),
      _RowData('Crossings', r1.intersections.toDouble(),
          r2.intersections.toDouble(),
          higherIsBetter: true),
      _RowData('Overlaps', r1.overlaps.toDouble(), r2.overlaps.toDouble(),
          higherIsBetter: true),
      _RowData('Dir. Changes', r1.directionChanges.toDouble(),
          r2.directionChanges.toDouble(),
          higherIsBetter: true),
      _RowData('Entropy', r1.entropy * 100, r2.entropy * 100,
          higherIsBetter: true),
      _RowData('Shoulder Surf %', r1.shoulderSurfRisk.score * 100,
          r2.shoulderSurfRisk.score * 100,
          higherIsBetter: false),
      _RowData('Smudge %', r1.smudgeRisk.score * 100,
          r2.smudgeRisk.score * 100,
          higherIsBetter: false),
      _RowData('Dictionary %', r1.dictionaryRisk.score * 100,
          r2.dictionaryRisk.score * 100,
          higherIsBetter: false),
      _RowData('Brute-Force %', r1.bruteForceRisk.score * 100,
          r2.bruteForceRisk.score * 100,
          higherIsBetter: false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'METRIC',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textHint,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'A',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'B',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          ...rows.map((row) => _TableRow(data: row)),
        ],
      ),
    );
  }
}

class _RowData {
  final String label;
  final double v1;
  final double v2;
  final bool higherIsBetter;

  const _RowData(
      this.label,
      this.v1,
      this.v2, {
        required this.higherIsBetter,
      });
}

class _TableRow extends StatelessWidget {
  final _RowData data;

  const _TableRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool tied = data.v1 == data.v2;

    final bool aBetter =
    data.higherIsBetter ? data.v1 > data.v2 : data.v1 < data.v2;
    final bool bBetter =
    data.higherIsBetter ? data.v2 > data.v1 : data.v2 < data.v1;

    final Color c1 = tied
        ? AppTheme.textSecondary
        : aBetter
        ? AppTheme.riskLow
        : AppTheme.riskHigh;

    final Color c2 = tied
        ? AppTheme.textSecondary
        : bBetter
        ? AppTheme.riskLow
        : AppTheme.riskHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _format(data.v1),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: c1,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _format(data.v2),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: c2,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

class _WinnerBanner extends StatelessWidget {
  final PatternAnalysisResult r1;
  final PatternAnalysisResult r2;

  const _WinnerBanner({
    required this.r1,
    required this.r2,
  });

  @override
  Widget build(BuildContext context) {
    final bool tied = r1.compositeScore == r2.compositeScore;
    final bool aWins = r1.compositeScore > r2.compositeScore;

    final String title = tied
        ? 'Both patterns score equally'
        : 'Pattern ${aWins ? 'A' : 'B'} is stronger';

    final String detail = tied
        ? 'Try different structures to see a clearer difference.'
        : 'Score difference: ${(r1.compositeScore - r2.compositeScore).abs().toStringAsFixed(1)} points';

    final Color color = tied
        ? AppTheme.textSecondary
        : aWins
        ? AppTheme.strongColor
        : AppTheme.mediumColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            tied ? Icons.balance_rounded : Icons.emoji_events_rounded,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}