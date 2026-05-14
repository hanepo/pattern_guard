import 'package:flutter/material.dart';
import '../models/pattern_model.dart';
import '../utils/app_theme.dart';

class MetricsPanel extends StatelessWidget {
  final PatternAnalysisResult result;

  const MetricsPanel({super.key, required this.result});

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
          Text(
            'PATTERN METRICS',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          // Grid of metric chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Nodes',
                value: '${result.nodeCount}',
                icon: Icons.circle_outlined,
                color: result.nodeCount >= 7
                    ? AppTheme.riskLow
                    : result.nodeCount >= 5
                    ? AppTheme.riskMedium
                    : AppTheme.riskCritical,
              ),
              _MetricChip(
                label: 'Length',
                value: result.physicalLength.toStringAsFixed(1),
                icon: Icons.straighten,
                color: result.physicalLength >= 8
                    ? AppTheme.riskLow
                    : result.physicalLength >= 5
                    ? AppTheme.riskMedium
                    : AppTheme.riskHigh,
              ),
              _MetricChip(
                label: 'Crossings',
                value: '${result.intersections}',
                icon: Icons.swap_calls,
                color: result.intersections >= 2
                    ? AppTheme.riskLow
                    : result.intersections == 1
                    ? AppTheme.riskMedium
                    : AppTheme.riskHigh,
              ),
              _MetricChip(
                label: 'Overlaps',
                value: '${result.overlaps}',
                icon: Icons.layers_outlined,
                color: result.overlaps >= 2
                    ? AppTheme.riskLow
                    : result.overlaps == 1
                    ? AppTheme.riskMedium
                    : AppTheme.riskHigh,
              ),
              _MetricChip(
                label: 'Dir. Changes',
                value: '${result.directionChanges}',
                icon: Icons.alt_route,
                color: result.directionChanges >= 4
                    ? AppTheme.riskLow
                    : result.directionChanges >= 2
                    ? AppTheme.riskMedium
                    : AppTheme.riskHigh,
              ),
              _MetricChip(
                label: 'Entropy',
                value: result.entropy.toStringAsFixed(2),
                icon: Icons.shuffle,
                color: result.entropy >= 0.7
                    ? AppTheme.riskLow
                    : result.entropy >= 0.4
                    ? AppTheme.riskMedium
                    : AppTheme.riskHigh,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          // Boolean flags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FlagChip(
                label: 'Blocklist match',
                value: result.isInBlocklist,
                dangerIfTrue: true,
              ),
              _FlagChip(
                label: 'Biased start node',
                value: result.hasTopLeftStart,
                dangerIfTrue: true,
              ),
              _FlagChip(
                label: 'Symmetrical',
                value: result.isSymmetrical,
                dangerIfTrue: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textHint,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  final bool value;
  final bool dangerIfTrue;

  const _FlagChip({
    required this.label,
    required this.value,
    required this.dangerIfTrue,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDanger = dangerIfTrue && value;
    final Color color = isDanger ? AppTheme.riskHigh : AppTheme.riskLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}