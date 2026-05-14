import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pattern_model.dart';
import '../utils/app_theme.dart';

/// Spider/radar chart showing vulnerability across all 4 attack types.
/// Pure CustomPaint — no external chart library needed.
class AttackRadarChart extends StatelessWidget {
  final PatternAnalysisResult result;

  const AttackRadarChart({super.key, required this.result});

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
              const Icon(Icons.radar, size: 14, color: AppTheme.accent),
              const SizedBox(width: 8),
              Text('ATTACK RADAR',
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Outer edge = 100% vulnerable. Inner = safe.',
            style: TextStyle(fontSize: 11, color: AppTheme.textHint),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _RadarPainter(result: result),
              size: const Size(double.infinity, 220),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(
                  label: 'Shoulder Surf',
                  score: result.shoulderSurfRisk.score,
                  color: _attackColor(result.shoulderSurfRisk.level)),
              _LegendItem(
                  label: 'Smudge',
                  score: result.smudgeRisk.score,
                  color: _attackColor(result.smudgeRisk.level)),
              _LegendItem(
                  label: 'Dictionary',
                  score: result.dictionaryRisk.score,
                  color: _attackColor(result.dictionaryRisk.level)),
              _LegendItem(
                  label: 'Brute-Force',
                  score: result.bruteForceRisk.score,
                  color: _attackColor(result.bruteForceRisk.level)),
              _LegendItem(
                  label: 'Thermal',
                  score: result.thermalRisk.score,
                  color: _attackColor(result.thermalRisk.level)),
            ],
          ),
        ],
      ),
    );
  }

  Color _attackColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return AppTheme.riskLow;
      case RiskLevel.medium:
        return AppTheme.riskMedium;
      case RiskLevel.high:
        return AppTheme.riskHigh;
      case RiskLevel.critical:
        return AppTheme.riskCritical;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _LegendItem(
      {required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          '$label ${(score * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final PatternAnalysisResult result;

  _RadarPainter({required this.result});

  static const List<String> _labels = [
    'Shoulder\nSurf',
    'Smudge',
    'Dictionary',
    'Brute\nForce',
    'Thermal',
  ];

  List<double> get _scores => [
    result.shoulderSurfRisk.score,
    result.smudgeRisk.score,
    result.dictionaryRisk.score,
    result.bruteForceRisk.score,
    result.thermalRisk.score,
  ];

  Color _levelColor(RiskLevel l) {
    switch (l) {
      case RiskLevel.low:
        return AppTheme.riskLow;
      case RiskLevel.medium:
        return AppTheme.riskMedium;
      case RiskLevel.high:
        return AppTheme.riskHigh;
      case RiskLevel.critical:
        return AppTheme.riskCritical;
    }
  }

  List<RiskLevel> get _levels => [
    result.shoulderSurfRisk.level,
    result.smudgeRisk.level,
    result.dictionaryRisk.level,
    result.bruteForceRisk.level,
    result.thermalRisk.level,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(cx, cy) - 36.0;
    const n = 5; // pentagon
    // Start from top (270°)
    const startAngle = -pi / 2;

    // ── Grid rings ────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int ring = 1; ring <= 4; ring++) {
      final r = maxR * ring / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = startAngle + 2 * pi * i / n;
        final x = cx + r * cos(angle);
        final y = cy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);

      // Ring label (25%, 50%, 75%, 100%)
      final pct = '${ring * 25}%';
      final tp = TextPainter(
        text: TextSpan(
          text: pct,
          style: const TextStyle(
              fontSize: 8,
              color: AppTheme.textHint,
              fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx + 3, cy - r - 10));
    }

    // ── Axis lines ────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = AppTheme.borderBright
      ..strokeWidth = 0.8;

    for (int i = 0; i < n; i++) {
      final angle = startAngle + 2 * pi * i / n;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + maxR * cos(angle), cy + maxR * sin(angle)),
        axisPaint,
      );
    }

    // ── Data polygon ──────────────────────────────────────────────────────
    final scores = _scores;
    final levels = _levels;

    // Filled area
    final fillPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = startAngle + 2 * pi * i / n;
      final r = maxR * scores[i];
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        fillPath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
      }
    }
    fillPath.close();

    final fillPaint = Paint()
      ..color = AppTheme.riskHigh.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppTheme.riskHigh.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fillPath, strokePaint);

    // Data points
    for (int i = 0; i < n; i++) {
      final angle = startAngle + 2 * pi * i / n;
      final r = maxR * scores[i];
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      final dotColor = _levelColor(levels[i]);

      canvas.drawCircle(
          Offset(x, y), 5, Paint()..color = dotColor..style = PaintingStyle.fill);
      canvas.drawCircle(
          Offset(x, y),
          5,
          Paint()
            ..color = AppTheme.bg
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // ── Labels ────────────────────────────────────────────────────────────
    final labels = _labels;
    for (int i = 0; i < n; i++) {
      final angle = startAngle + 2 * pi * i / n;
      final labelR = maxR + 26;
      final lx = cx + labelR * cos(angle);
      final ly = cy + labelR * sin(angle);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _levelColor(levels[i]),
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 60);

      tp.paint(
          canvas,
          Offset(
            lx - tp.width / 2,
            ly - tp.height / 2,
          ));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.result != result;
}