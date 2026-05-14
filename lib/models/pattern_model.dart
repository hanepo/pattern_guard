import 'dart:math';
import 'dart:ui';

// Represents a single node on the 3x3 grid (0-8)
class PatternNode {
  final int index;
  final int row;
  final int col;

  const PatternNode(this.index) : row = index ~/ 3, col = index % 3;

  Offset get position => Offset(col.toDouble(), row.toDouble());

  @override
  bool operator ==(Object other) =>
      other is PatternNode && other.index == index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'Node($index)';
}

// Attack risk levels
enum RiskLevel { low, medium, high, critical }

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
    }
  }

  String get emoji {
    switch (this) {
      case RiskLevel.low:
        return '✓';
      case RiskLevel.medium:
        return '!';
      case RiskLevel.high:
        return '!!';
      case RiskLevel.critical:
        return '✗';
    }
  }
}

// Overall strength category
enum StrengthCategory {
  weakest,
  weak,
  weakToMedium,
  medium,
  mediumToStrong,
  strong,
  strongest,
}

extension StrengthCategoryExtension on StrengthCategory {
  String get label {
    switch (this) {
      case StrengthCategory.weakest:
        return 'WEAKEST';
      case StrengthCategory.weak:
        return 'WEAK';
      case StrengthCategory.weakToMedium:
        return 'WEAK–MEDIUM';
      case StrengthCategory.medium:
        return 'MEDIUM';
      case StrengthCategory.mediumToStrong:
        return 'MEDIUM–STRONG';
      case StrengthCategory.strong:
        return 'STRONG';
      case StrengthCategory.strongest:
        return 'STRONGEST';
    }
  }

  String get description {
    switch (this) {
      case StrengthCategory.weakest:
        return 'Extremely vulnerable — trivially guessed by any attack.';
      case StrengthCategory.weak:
        return 'This pattern is highly vulnerable to common attacks.';
      case StrengthCategory.weakToMedium:
        return 'Below average protection; easily defeated by several attacks.';
      case StrengthCategory.medium:
        return 'This pattern offers moderate protection but can be improved.';
      case StrengthCategory.mediumToStrong:
        return 'Above average — resistant to most casual attacks.';
      case StrengthCategory.strong:
        return 'This pattern provides strong resistance to common attacks.';
      case StrengthCategory.strongest:
        return 'Excellent — highly resilient against all known attack types.';
    }
  }
}

// Per-attack risk result
class AttackRisk {
  final String attackName;
  final String description;
  final RiskLevel level;
  final double score; // 0.0 - 1.0 (0 = safe, 1 = very vulnerable)
  final String explanation;
  final String mitigation;

  const AttackRisk({
    required this.attackName,
    required this.description,
    required this.level,
    required this.score,
    required this.explanation,
    required this.mitigation,
  });
}

// Full analysis result
class PatternAnalysisResult {
  final List<int> pattern;
  final bool passesValidation;
  final String? validationFailReason;

  // Raw metrics
  final int nodeCount;
  final double physicalLength;
  final int intersections;
  final int overlaps;
  final int directionChanges;
  final double entropy;
  final bool hasTopLeftStart;
  final bool isInBlocklist;
  final bool isSymmetrical;

  // Composite score (0-100)
  final double compositeScore;

  // Per-attack risks
  final AttackRisk shoulderSurfRisk;
  final AttackRisk smudgeRisk;
  final AttackRisk dictionaryRisk;
  final AttackRisk bruteForceRisk;
  final AttackRisk thermalRisk;

  // Pattern space analysis
  final int
  patternSearchSpace; // total valid Android patterns for this node count
  final int effectiveSearchSpace; // after reducing for user-behaviour biases
  final double
  timeToCrackHours; // estimated hours with Android lockout (5 attempts/30 s)

  // Overall
  final StrengthCategory strength;
  final List<String> improvements;

  const PatternAnalysisResult({
    required this.pattern,
    required this.passesValidation,
    this.validationFailReason,
    required this.nodeCount,
    required this.physicalLength,
    required this.intersections,
    required this.overlaps,
    required this.directionChanges,
    required this.entropy,
    required this.hasTopLeftStart,
    required this.isInBlocklist,
    required this.isSymmetrical,
    required this.compositeScore,
    required this.shoulderSurfRisk,
    required this.smudgeRisk,
    required this.dictionaryRisk,
    required this.bruteForceRisk,
    required this.thermalRisk,
    required this.patternSearchSpace,
    required this.effectiveSearchSpace,
    required this.timeToCrackHours,
    required this.strength,
    required this.improvements,
  });

  // Convenience: overall attack risk (worst case)
  RiskLevel get overallAttackRisk {
    final risks = [
      shoulderSurfRisk.level,
      smudgeRisk.level,
      dictionaryRisk.level,
      bruteForceRisk.level,
      thermalRisk.level,
    ];
    if (risks.contains(RiskLevel.critical)) return RiskLevel.critical;
    if (risks.contains(RiskLevel.high)) return RiskLevel.high;
    if (risks.contains(RiskLevel.medium)) return RiskLevel.medium;
    return RiskLevel.low;
  }
}

// Session history entry
class HistoryEntry {
  final List<int> pattern;
  final double score;
  final StrengthCategory strength;
  final DateTime timestamp;

  const HistoryEntry({
    required this.pattern,
    required this.score,
    required this.strength,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'pattern': pattern,
    'score': score,
    'strength': strength.name,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    StrengthCategory str;
    final raw = json['strength'];
    if (raw is String) {
      str = StrengthCategory.values.firstWhere(
            (e) => e.name == raw,
        orElse: () => StrengthCategory.weak,
      );
    } else {
      // Legacy: old entries stored index of 3-value enum (0=weak,1=medium,2=strong)
      const legacy = [
        StrengthCategory.weak,
        StrengthCategory.medium,
        StrengthCategory.strong,
      ];
      str = (raw is int && raw >= 0 && raw < legacy.length)
          ? legacy[raw]
          : StrengthCategory.weak;
    }
    return HistoryEntry(
      pattern: List<int>.from(json['pattern']),
      score: (json['score'] as num).toDouble(),
      strength: str,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}