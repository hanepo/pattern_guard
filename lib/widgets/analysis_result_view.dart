import 'dart:math';
import 'package:flutter/material.dart';

import '../models/pattern_model.dart';
import '../utils/app_theme.dart';

class AnalysisResultView extends StatelessWidget {
  final PatternAnalysisResult result;

  const AnalysisResultView({
    super.key,
    required this.result,
  });

  Color get strengthColor {
    switch (result.strength) {
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
    return Column(
      children: [
        _StrengthCard(result: result, color: strengthColor),
        const SizedBox(height: 16),
        _MetricsPanel(result: result),
        const SizedBox(height: 16),
        _AttackExposure(result: result),
        const SizedBox(height: 16),
        _AttackRadar(result: result),
        const SizedBox(height: 16),
        _PatternSpace(result: result),
        const SizedBox(height: 16),
        _TipsCard(result: result),
      ],
    );
  }
}

class _StrengthCard extends StatelessWidget {
  final PatternAnalysisResult result;
  final Color color;

  const _StrengthCard({
    required this.result,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Text(
            result.compositeScore.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '/10',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.strength.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saved analysis result for this selected pattern.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
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

class _MetricsPanel extends StatelessWidget {
  final PatternAnalysisResult result;

  const _MetricsPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'PATTERN METRICS',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _MetricChip(label: 'Nodes', value: '${result.nodeCount}'),
          _MetricChip(
              label: 'Length',
              value: result.physicalLength.toStringAsFixed(1)),
          _MetricChip(label: 'Crossings', value: '${result.intersections}'),
          _MetricChip(label: 'Overlaps', value: '${result.overlaps}'),
          _MetricChip(
              label: 'Dir. Changes', value: '${result.directionChanges}'),
          _MetricChip(label: 'Entropy', value: result.entropy.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textHint, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _AttackExposure extends StatelessWidget {
  final PatternAnalysisResult result;

  const _AttackExposure({required this.result});

  @override
  Widget build(BuildContext context) {
    final risks = [
      _RiskItem('Shoulder Surfing', result.shoulderSurfRisk.score),
      _RiskItem('Smudge Attack', result.smudgeRisk.score),
      _RiskItem('Dictionary Attack', result.dictionaryRisk.score),
      _RiskItem('Brute-Force Attack', result.bruteForceRisk.score),
      _RiskItem('Thermal Attack', result.thermalRisk.score),
    ];

    return _SectionCard(
      title: 'ATTACK EXPOSURE',
      child: Column(
        children: risks.map((risk) => _RiskBar(item: risk)).toList(),
      ),
    );
  }
}

class _RiskItem {
  final String label;
  final double value;

  const _RiskItem(this.label, this.value);
}

class _RiskBar extends StatelessWidget {
  final _RiskItem item;

  const _RiskBar({required this.item});

  Color get color {
    final percent = item.value * 100;
    if (percent < 30) return AppTheme.riskLow;
    if (percent < 60) return AppTheme.riskMedium;
    return AppTheme.riskHigh;
  }

  String get level {
    final percent = item.value * 100;
    if (percent < 30) return 'LOW RISK';
    if (percent < 60) return 'MEDIUM RISK';
    return 'HIGH RISK';
  }

  @override
  Widget build(BuildContext context) {
    final percent = item.value * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${percent.toStringAsFixed(0)}% $level',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttackRadar extends StatelessWidget {
  final PatternAnalysisResult result;

  const _AttackRadar({required this.result});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ATTACK RADAR',
      subtitle: 'Outer edge = 100% vulnerable. Inner = safe.',
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: CustomPaint(
              painter: _RadarPainter(result: result),
              child: const SizedBox.expand(),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _LegendDot('Shoulder ${_percent(result.shoulderSurfRisk.score)}',
                  _riskColor(result.shoulderSurfRisk.score)),
              _LegendDot('Smudge ${_percent(result.smudgeRisk.score)}',
                  _riskColor(result.smudgeRisk.score)),
              _LegendDot('Dictionary ${_percent(result.dictionaryRisk.score)}',
                  _riskColor(result.dictionaryRisk.score)),
              _LegendDot('Brute-Force ${_percent(result.bruteForceRisk.score)}',
                  _riskColor(result.bruteForceRisk.score)),
              _LegendDot('Thermal ${_percent(result.thermalRisk.score)}',
                  _riskColor(result.thermalRisk.score)),
            ],
          ),
        ],
      ),
    );
  }

  static String _percent(double value) => '${(value * 100).toStringAsFixed(0)}%';
}

class _LegendDot extends StatelessWidget {
  final String text;
  final Color color;

  const _LegendDot(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final PatternAnalysisResult result;

  _RadarPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.34;

    final values = [
      result.shoulderSurfRisk.score,
      result.smudgeRisk.score,
      result.dictionaryRisk.score,
      result.bruteForceRisk.score,
      result.thermalRisk.score,
    ];

    final labels = [
      'Shoulder\nSurf',
      'Smudge',
      'Dictionary',
      'Brute\nForce',
      'Thermal',
    ];

    final gridPaint = Paint()
      ..color = AppTheme.border.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int level = 1; level <= 4; level++) {
      final r = radius * level / 4;
      final path = Path();

      for (int i = 0; i < 5; i++) {
        final angle = -pi / 2 + (2 * pi * i / 5);
        final p = center + Offset(cos(angle) * r, sin(angle) * r);

        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi * i / 5);
      final end = center + Offset(cos(angle) * radius, sin(angle) * radius);

      canvas.drawLine(center, end, gridPaint);

      final labelPos = center +
          Offset(cos(angle) * (radius + 34), sin(angle) * (radius + 34));

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: AppTheme.accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
    }

    final path = Path();

    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi * i / 5);
      final r = radius * values[i].clamp(0.0, 1.0);
      final p = center + Offset(cos(angle) * r, sin(angle) * r);

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi * i / 5);
      final r = radius * values[i].clamp(0.0, 1.0);
      final p = center + Offset(cos(angle) * r, sin(angle) * r);

      canvas.drawCircle(p, 4, Paint()..color = _riskColor(values[i]));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

class _PatternSpace extends StatelessWidget {
  final PatternAnalysisResult result;

  const _PatternSpace({required this.result});

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

    return _SectionCard(
      title: 'PATTERN SPACE ANALYSIS',
      subtitle: 'Based on Android valid pattern count and behavioural biases.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SpaceBox(
                  title: _formatNumber(result.patternSearchSpace),
                  subtitle: 'Total Space',
                  icon: Icons.grid_view_rounded,
                  color: spaceColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SpaceBox(
                  title: _formatNumber(result.effectiveSearchSpace),
                  subtitle: 'Effective Space',
                  icon: Icons.filter_alt_rounded,
                  color: AppTheme.riskMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SpaceBox(
                  title: _formatTime(result.timeToCrackHours),
                  subtitle: 'Est. Crack Time',
                  icon: Icons.timer_outlined,
                  color: timeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Crack time assumes an automated attacker exploiting Android\'s '
            '5-attempt lockout (10 guesses/min sustained rate). '
            'Effective space shrinks when starting nodes or pattern shapes '
            'match statistically common user behaviour (Sun et al., 2014).',
            style: TextStyle(fontSize: 10, color: AppTheme.textHint, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SpaceBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SpaceBox({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final PatternAnalysisResult result;

  const _TipsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'IMPROVEMENT TIPS',
      child: Column(
        children: result.improvements
            .map(
              (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    color: AppTheme.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textHint,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

Color _riskColor(double value) {
  final percent = value * 100;
  if (percent < 30) return AppTheme.riskLow;
  if (percent < 60) return AppTheme.riskMedium;
  return AppTheme.riskHigh;
}