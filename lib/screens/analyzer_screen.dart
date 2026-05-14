import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pattern_model.dart';
import '../utils/pattern_analyzer.dart';
import '../utils/app_theme.dart';
import '../utils/sound_service.dart';
import '../widgets/pattern_grid.dart';
import '../widgets/live_strength_meter.dart';
import '../widgets/attack_risk_card.dart';
import '../widgets/metrics_panel.dart';
import '../widgets/attack_radar_chart.dart';

class AnalyzerScreen extends StatefulWidget {
  final Future<void> Function(PatternAnalysisResult)? onAnalysisComplete;

  const AnalyzerScreen({
    super.key,
    this.onAnalysisComplete,
  });

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen>
    with TickerProviderStateMixin {
  final _gridKey = GlobalKey<PatternGridState>();
  final _sound = SoundService();

  List<int> _currentPattern = [];
  PatternAnalysisResult? _liveResult;
  PatternAnalysisResult? _finalResult;

  bool _analysisVisible = false;
  bool _isSaved = false;
  bool _isDrawingPattern = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPatternChanged(List<int> pattern, PatternAnalysisResult? liveResult) {
    setState(() {
      _currentPattern = pattern;
      _liveResult = liveResult;
      _isSaved = false;

      if (pattern.isEmpty) {
        _analysisVisible = false;
        _finalResult = null;
      }
    });
  }

  void _onPatternComplete(List<int> pattern) {
    if (pattern.length < 2) return;

    final result = PatternAnalyzer.analyze(pattern);

    if (!result.passesValidation) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.validationFailReason ?? 'Pattern rejected.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.weakColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _liveResult = null;
        _analysisVisible = false;
        _finalResult = null;
        _isSaved = false;
      });

      return;
    }

    setState(() {
      _finalResult = result;
      _analysisVisible = true;
      _isSaved = false;
    });

    _fadeController.forward(from: 0);
    _slideController.forward(from: 0);
    _sound.playStrengthResult(result.strength);
  }

  Future<void> _saveCurrentAnalysis() async {
    if (_finalResult == null || _isSaved) return;

    if (widget.onAnalysisComplete == null) {
      _showSnackBar(
        message: 'History saving is not available.',
        color: AppTheme.weakColor,
        icon: Icons.error_outline,
      );
      return;
    }

    await widget.onAnalysisComplete?.call(_finalResult!);

    if (!mounted) return;

    setState(() {
      _isSaved = true;
    });

    _showSnackBar(
      message: 'Analysis saved to History.',
      color: AppTheme.accent,
      icon: Icons.check_circle_outline,
    );
  }

  void _showSnackBar({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reset() {
    HapticFeedback.lightImpact();
    _gridKey.currentState?.reset();

    setState(() {
      _currentPattern = [];
      _liveResult = null;
      _finalResult = null;
      _analysisVisible = false;
      _isSaved = false;
    });

    _fadeController.reset();
    _slideController.reset();
  }

  Color get _strengthColor {
    if (_finalResult == null) return AppTheme.textHint;
    return _categoryColor(_finalResult!.strength);
  }

  static Color _categoryColor(StrengthCategory strength) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: _isDrawingPattern
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGlow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.accent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Pattern Strength Analyzer'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reset',
                  onPressed: _reset,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildGridCard(),
                    const SizedBox(height: 16),
                    LiveStrengthMeter(
                      result: _liveResult ?? _finalResult,
                      hasPattern: _currentPattern.isNotEmpty,
                    ),
                    const SizedBox(height: 16),
                    if (_analysisVisible && _finalResult != null)
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _buildFullAnalysis(_finalResult!),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Draw your pattern',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'Connect at least 4 nodes. Lift your finger to analyse.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildGridCard() {
    return Listener(
      onPointerDown: (_) => setState(() => _isDrawingPattern = true),
      onPointerUp: (_) => setState(() => _isDrawingPattern = false),
      onPointerCancel: (_) => setState(() => _isDrawingPattern = false),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _currentPattern.isNotEmpty
                ? _strengthColor.withOpacity(0.3)
                : AppTheme.border,
          ),
          boxShadow: _currentPattern.isNotEmpty
              ? [
            BoxShadow(
              color: _strengthColor.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ]
              : null,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 260,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: PatternGrid(
                  key: _gridKey,
                  onPatternChanged: _onPatternChanged,
                  onPatternComplete: _onPatternComplete,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              border: const Border(
                top: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 14,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  _currentPattern.isEmpty
                      ? 'Touch and drag to draw'
                      : '${_currentPattern.length} node${_currentPattern.length == 1 ? '' : 's'} connected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_currentPattern.isNotEmpty)
                  GestureDetector(
                    onTap: _reset,
                    child: const Text(
                      'CLEAR',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFullAnalysis(PatternAnalysisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!result.passesValidation)
          _ValidationBanner(
            reason: result.validationFailReason ?? '',
          ),

        _OverallScoreCard(result: result),

        const SizedBox(height: 12),

        _SaveHistoryButton(
          isSaved: _isSaved,
          onPressed: _saveCurrentAnalysis,
        ),

        const SizedBox(height: 16),

        MetricsPanel(result: result),

        const SizedBox(height: 16),

        _SectionHeader(
          label: 'ATTACK EXPOSURE',
          icon: Icons.security,
        ),

        const SizedBox(height: 10),

        Text(
          'Tap each card to see detailed analysis and mitigation advice.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 12),

        AttackRiskCard(risk: result.shoulderSurfRisk),
        AttackRiskCard(risk: result.smudgeRisk),
        AttackRiskCard(risk: result.dictionaryRisk),
        AttackRiskCard(risk: result.bruteForceRisk),
        AttackRiskCard(risk: result.thermalRisk),

        const SizedBox(height: 16),

        AttackRadarChart(result: result),

        const SizedBox(height: 16),

        _PatternSpaceCard(result: result),

        const SizedBox(height: 16),

        _ImprovementsCard(
          improvements: result.improvements,
        ),
      ],
    );
  }
}

class _SaveHistoryButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onPressed;

  const _SaveHistoryButton({
    required this.isSaved,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSaved ? null : onPressed,
        icon: Icon(
          isSaved ? Icons.check_circle_outline : Icons.save_outlined,
        ),
        label: Text(
          isSaved ? 'Saved to History' : 'Save to History',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isSaved ? AppTheme.surfaceElevated : AppTheme.accent,
          foregroundColor:
          isSaved ? AppTheme.textSecondary : Colors.white,
          disabledBackgroundColor: AppTheme.surfaceElevated,
          disabledForegroundColor: AppTheme.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  final String reason;

  const _ValidationBanner({
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.weakColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.weakColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: AppTheme.weakColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.weakColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  final PatternAnalysisResult result;

  const _OverallScoreCard({
    required this.result,
  });

  Color get _color => _AnalyzerScreenState._categoryColor(result.strength);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _color.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: result.compositeScore),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (ctx, val, _) => Text(
                  val.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: _color,
                    fontFamily: 'monospace',
                    height: 1,
                  ),
                ),
              ),
              Text(
                '/10',
                style: TextStyle(
                  fontSize: 13,
                  color: _color.withOpacity(0.6),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    result.strength.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _color,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.strength.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ImprovementsCard extends StatelessWidget {
  final List<String> improvements;

  const _ImprovementsCard({
    required this.improvements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'IMPROVEMENT TIPS',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...improvements.map(
                (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternSpaceCard extends StatelessWidget {
  final PatternAnalysisResult result;

  const _PatternSpaceCard({
    required this.result,
  });

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatTime(double hours) {
    if (hours < 1 / 60) return '< 1 min';

    if (hours < 1) {
      final mins = (hours * 60).round();
      return '~$mins min';
    }

    if (hours < 24) return '~${hours.toStringAsFixed(1)} hrs';

    final days = (hours / 24).round();
    return '~$days days';
  }

  @override
  Widget build(BuildContext context) {
    final spaceColor = result.patternSearchSpace >= 72912
        ? AppTheme.riskLow
        : result.patternSearchSpace >= 7152
        ? AppTheme.riskMedium
        : AppTheme.riskHigh;

    final timeColor = result.timeToCrackHours >= 1.0
        ? AppTheme.riskLow
        : result.timeToCrackHours >= 0.1
        ? AppTheme.riskMedium
        : AppTheme.riskCritical;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_outlined,
                size: 14,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'PATTERN SPACE ANALYSIS',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on Android\'s valid pattern count and behavioural biases.',
            style: TextStyle(fontSize: 11, color: AppTheme.textHint),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SpaceStat(
                  label: 'Total Space',
                  value: _formatNumber(result.patternSearchSpace),
                  sub: '${result.nodeCount}-node patterns',
                  color: spaceColor,
                  icon: Icons.grid_view,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SpaceStat(
                  label: 'Effective Space',
                  value: _formatNumber(result.effectiveSearchSpace),
                  sub: 'after user-bias reduction',
                  color: AppTheme.riskMedium,
                  icon: Icons.filter_list,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SpaceStat(
                  label: 'Est. Crack Time',
                  value: _formatTime(result.timeToCrackHours),
                  sub: '5 attempts / 30 s lockout',
                  color: timeColor,
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Crack time assumes an automated attacker exploiting Android\'s '
                '5-attempt lockout (10 guesses/min sustained rate). '
                'Effective space shrinks when starting nodes or pattern shapes '
                'match statistically common user behaviour (Sun et al., 2014).',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _SpaceStat({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}