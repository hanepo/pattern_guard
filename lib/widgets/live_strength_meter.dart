import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/pattern_model.dart';

class LiveStrengthMeter extends StatelessWidget {
  final PatternAnalysisResult? result;
  final bool hasPattern;

  const LiveStrengthMeter({
    super.key,
    required this.result,
    required this.hasPattern,
  });

  Color get _barColor {
    if (result == null) return AppTheme.textHint;
    switch (result!.strength) {
      case StrengthCategory.weakest:        return AppTheme.weakestColor;
      case StrengthCategory.weak:           return AppTheme.weakColor;
      case StrengthCategory.weakToMedium:   return AppTheme.weakToMediumColor;
      case StrengthCategory.medium:         return AppTheme.mediumColor;
      case StrengthCategory.mediumToStrong: return AppTheme.mediumToStrongColor;
      case StrengthCategory.strong:         return AppTheme.strongColor;
      case StrengthCategory.strongest:      return AppTheme.strongestColor;
    }
  }

  String get _label {
    if (!hasPattern) return 'Draw a pattern to begin';
    if (result == null) return 'Analysing...';
    if (!result!.passesValidation) return result!.validationFailReason ?? 'Invalid pattern';
    return result!.strength.label;
  }

  double get _progress {
    if (result == null) return 0;
    return (result!.compositeScore / 10.0).clamp(0.0, 1.0);
  }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STRENGTH',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (result != null)
                Text(
                  '${result!.compositeScore.toStringAsFixed(1)}/10',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _barColor,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Animated bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (ctx, val, _) {
                return LinearProgressIndicator(
                  value: val,
                  minHeight: 8,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Three segment markers
          Row(
            children: [
              Expanded(
                child: _SegmentLabel(
                  label: 'WEAK',
                  color: AppTheme.weakColor,
                  isActive: result?.strength == StrengthCategory.weak,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegmentLabel(
                  label: 'MEDIUM',
                  color: AppTheme.mediumColor,
                  isActive: result?.strength == StrengthCategory.medium,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegmentLabel(
                  label: 'STRONG',
                  color: AppTheme.strongColor,
                  isActive: result?.strength == StrengthCategory.strong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              color: hasPattern ? _barColor : AppTheme.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;

  const _SegmentLabel({
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? color.withOpacity(0.5) : AppTheme.border,
          width: 1,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? color : AppTheme.textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}