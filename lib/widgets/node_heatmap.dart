import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class NodeHeatmap extends StatelessWidget {
  final Map<int, int> nodeFrequency; // node index -> count
  final int totalPatterns;

  const NodeHeatmap({
    super.key,
    required this.nodeFrequency,
    required this.totalPatterns,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPatterns == 0) {
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
            Text('NODE HEATMAP', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Analyse patterns to build heatmap',
                style: TextStyle(color: AppTheme.textHint, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final maxCount = nodeFrequency.values.isEmpty
        ? 1
        : nodeFrequency.values.reduce((a, b) => a > b ? a : b);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NODE HEATMAP', style: Theme.of(context).textTheme.labelLarge),
              Text(
                '$totalPatterns pattern${totalPatterns == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 9,
              itemBuilder: (ctx, i) {
                final count = nodeFrequency[i] ?? 0;
                final heat = maxCount > 0 ? count / maxCount : 0.0;
                final pct =
                totalPatterns > 0 ? (count / totalPatterns * 100) : 0;
                return _HeatCell(
                  nodeIndex: i,
                  heat: heat,
                  count: count,
                  percent: pct.toStringAsFixed(0),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            children: [
              const Text(
                'USAGE: ',
                style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.textHint,
                  letterSpacing: 0.6,
                ),
              ),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [AppTheme.border, AppTheme.accent],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'High',
                style: TextStyle(fontSize: 9, color: AppTheme.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  final int nodeIndex;
  final double heat; // 0–1
  final int count;
  final String percent;

  const _HeatCell({
    required this.nodeIndex,
    required this.heat,
    required this.count,
    required this.percent,
  });

  Color get _heatColor {
    if (heat == 0) return AppTheme.border;
    // Interpolate from cool blue to hot red/orange
    if (heat < 0.33) {
      return Color.lerp(AppTheme.border, AppTheme.riskMedium, heat * 3)!;
    } else if (heat < 0.66) {
      return Color.lerp(AppTheme.riskMedium, AppTheme.riskHigh, (heat - 0.33) * 3)!;
    } else {
      return Color.lerp(AppTheme.riskHigh, AppTheme.riskCritical, (heat - 0.66) * 3)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _heatColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15 + heat * 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4 + heat * 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'N${nodeIndex + 1}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          if (count > 0) ...[
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              '$count uses',
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textHint,
              ),
            ),
          ] else
            Text(
              '0%',
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}