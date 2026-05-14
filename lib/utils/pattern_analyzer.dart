import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pattern_model.dart';
import '../utils/common_patterns.dart';

class PatternAnalyzer {
  static const List<int> _biasedStartNodes = [0, 1, 2, 3];

  // =========================
  // Geometry helpers
  // =========================

  static Offset _nodePos(int node) {
    return Offset((node % 3).toDouble(), (node ~/ 3).toDouble());
  }

  static double _distance(int a, int b) {
    final Offset pa = _nodePos(a);
    final Offset pb = _nodePos(b);
    final double dx = pb.dx - pa.dx;
    final double dy = pb.dy - pa.dy;
    return sqrt(dx * dx + dy * dy);
  }

  static double _angle(int a, int b) {
    final Offset pa = _nodePos(a);
    final Offset pb = _nodePos(b);
    return atan2(pb.dy - pa.dy, pb.dx - pa.dx);
  }

  // =========================
  // Android pattern rule
  // =========================

  static List<int> _insertIntermediates(List<int> rawPattern) {
    final List<int> result = <int>[];
    final Set<int> visited = <int>{};

    for (final int node in rawPattern) {
      if (visited.contains(node)) continue;

      if (result.isNotEmpty) {
        final int previous = result.last;
        final int? middle = _getIntermediate(previous, node);

        if (middle != null && !visited.contains(middle)) {
          result.add(middle);
          visited.add(middle);
        }
      }

      result.add(node);
      visited.add(node);
    }

    return result;
  }

  static int? _getIntermediate(int a, int b) {
    final int ar = a ~/ 3;
    final int ac = a % 3;
    final int br = b ~/ 3;
    final int bc = b % 3;

    final int dr = br - ar;
    final int dc = bc - ac;

    if (dr.abs() <= 1 && dc.abs() <= 1) return null;

    if (dr % 2 == 0 && dc % 2 == 0) {
      final int mr = ar + dr ~/ 2;
      final int mc = ac + dc ~/ 2;
      if (mr >= 0 && mr < 3 && mc >= 0 && mc < 3) {
        return mr * 3 + mc;
      }
    }

    return null;
  }

  // =========================
  // Pattern metrics
  // =========================

  static double _calcLength(List<int> pattern) {
    double total = 0.0;
    for (int i = 0; i < pattern.length - 1; i++) {
      total += _distance(pattern[i], pattern[i + 1]);
    }
    return total;
  }

  static int _calcDirectionChanges(List<int> pattern) {
    if (pattern.length < 3) return 0;

    int changes = 0;
    double previousAngle = _angle(pattern[0], pattern[1]);

    for (int i = 1; i < pattern.length - 1; i++) {
      final double currentAngle = _angle(pattern[i], pattern[i + 1]);
      double diff = (currentAngle - previousAngle).abs();

      if (diff > pi) {
        diff = 2 * pi - diff;
      }

      if (diff > 0.2) {
        changes++;
      }

      previousAngle = currentAngle;
    }

    return changes;
  }

  static bool _segmentsIntersect(Offset p1, Offset p2, Offset p3, Offset p4) {
    final double d1x = p2.dx - p1.dx;
    final double d1y = p2.dy - p1.dy;
    final double d2x = p4.dx - p3.dx;
    final double d2y = p4.dy - p3.dy;

    final double cross = d1x * d2y - d1y * d2x;
    if (cross.abs() < 1e-10) return false;

    final double t = ((p3.dx - p1.dx) * d2y - (p3.dy - p1.dy) * d2x) / cross;
    final double u = ((p3.dx - p1.dx) * d1y - (p3.dy - p1.dy) * d1x) / cross;

    return t > 0.01 && t < 0.99 && u > 0.01 && u < 0.99;
  }

  static int _calcIntersections(List<int> pattern) {
    int count = 0;
    final List<List<Offset>> segments = <List<Offset>>[];

    for (int i = 0; i < pattern.length - 1; i++) {
      segments.add(<Offset>[_nodePos(pattern[i]), _nodePos(pattern[i + 1])]);
    }

    for (int i = 0; i < segments.length; i++) {
      for (int j = i + 2; j < segments.length; j++) {
        if (_segmentsIntersect(
          segments[i][0],
          segments[i][1],
          segments[j][0],
          segments[j][1],
        )) {
          count++;
        }
      }
    }

    return count;
  }

  // Retraced segment count, not geometric crossing count.
  static int _calcOverlaps(List<int> pattern) {
    int count = 0;
    final Set<String> seen = <String>{};

    for (int i = 0; i < pattern.length - 1; i++) {
      final int a = pattern[i];
      final int b = pattern[i + 1];
      final String key = '${min(a, b)}-${max(a, b)}';

      if (seen.contains(key)) {
        count++;
      } else {
        seen.add(key);
      }
    }

    return count;
  }

  static double _calcEntropy(List<int> pattern) {
    if (pattern.length < 2) return 0.0;

    final int transitions = pattern.length - 1;

    // Direction entropy: quantize movements into compass directions.
    final Map<int, int> dirFreq = <int, int>{};
    for (int i = 0; i < transitions; i++) {
      final int dr = (pattern[i + 1] ~/ 3) - (pattern[i] ~/ 3);
      final int dc = (pattern[i + 1] % 3) - (pattern[i] % 3);
      final int key = dr * 10 + dc;
      dirFreq[key] = (dirFreq[key] ?? 0) + 1;
    }

    double dirH = 0.0;
    for (final int count in dirFreq.values) {
      final double p = count / transitions;
      dirH -= p * log(p) / ln2;
    }
    // Always normalize against full 8-direction space so short patterns
    // cannot trivially max out the score.
    const double maxDirH = 3.0; // log2(8) = 3.0
    final double normDir = (dirH / maxDirH).clamp(0.0, 1.0);

    // Node-distribution entropy: normalize against full 9-node grid.
    final Map<int, int> nodeFreq = <int, int>{};
    for (final int n in pattern) {
      nodeFreq[n] = (nodeFreq[n] ?? 0) + 1;
    }
    double nodeH = 0.0;
    final double nodeTotal = pattern.length.toDouble();
    for (final int count in nodeFreq.values) {
      final double p = count / nodeTotal;
      nodeH -= p * log(p) / ln2;
    }
    // Normalize against log2(9) ≈ 3.17 (full grid utilization).
    final double maxNodeH = log(9.0) / ln2;
    final double normNode = (nodeH / maxNodeH).clamp(0.0, 1.0);

    // Direction diversity: unique directions used vs 8 possible.
    final double dirRatio = (dirFreq.length / 8.0).clamp(0.0, 1.0);

    // Length penalty: patterns with fewer transitions have less opportunity
    // to demonstrate randomness, so cap their maximum achievable entropy.
    // 3 transitions → max 0.45, 5 → 0.70, 7 → 0.90, 8 → 1.0
    final double lengthCap = ((transitions - 2) / 6.0).clamp(0.0, 1.0);

    final double raw = normDir * 0.45 + normNode * 0.30 + dirRatio * 0.25;
    return (raw * lengthCap).clamp(0.0, 1.0);
  }

  static bool _isSymmetrical(List<int> pattern) {
    final List<int> horizontalMirror = pattern.map((int node) {
      final int row = node ~/ 3;
      final int col = node % 3;
      return row * 3 + (2 - col);
    }).toList();

    if (pattern.join(',') == horizontalMirror.join(',')) {
      return true;
    }

    final List<int> verticalMirror = pattern.map((int node) {
      final int row = node ~/ 3;
      final int col = node % 3;
      return (2 - row) * 3 + col;
    }).toList();

    return pattern.join(',') == verticalMirror.join(',');
  }

  // =========================
  // Risk helpers
  // =========================

  static RiskLevel _riskLevel(double risk) {
    if (risk < 0.30) return RiskLevel.low;
    if (risk < 0.55) return RiskLevel.medium;
    if (risk < 0.75) return RiskLevel.high;
    return RiskLevel.critical;
  }

  static AttackRisk _calcShoulderSurfRisk({
    required int nodeCount,
    required int directionChanges,
    required int intersections,
    required bool isSymmetrical,
    required bool isCommonPattern,
  }) {
    double risk = 0.0;

    if (nodeCount <= 4) {
      risk += 0.30;
    } else if (nodeCount <= 6) {
      risk += 0.15;
    }

    if (directionChanges <= 2) {
      risk += 0.25;
    } else if (directionChanges <= 4) {
      risk += 0.10;
    }

    if (intersections == 0) {
      risk += 0.15;
    } else if (intersections == 1) {
      risk += 0.05;
    }

    if (isSymmetrical) risk += 0.15;
    if (isCommonPattern) risk += 0.15;

    risk = risk.clamp(0.0, 1.0);

    return AttackRisk(
      attackName: 'Shoulder Surfing',
      description: 'Attacker observes your screen while you draw',
      level: _riskLevel(risk),
      score: risk,
      explanation: risk >= 0.5
          ? 'The pattern is visually easier to follow because it has limited visual disruption.'
          : 'The pattern has enough turns or crossings to make visual observation harder.',
      mitigation: risk >= 0.5
          ? 'Add more turns, avoid symmetry, and include crossing strokes.'
          : 'Good resistance. Still avoid drawing it in public.',
    );
  }

  static AttackRisk _calcSmudgeRisk({
    required int nodeCount,
    required int directionChanges,
    required int intersections,
    required int overlaps,
    required bool isSymmetrical,
  }) {
    double risk = 0.0;

    if (nodeCount <= 4) {
      risk += 0.25;
    } else if (nodeCount <= 6) {
      risk += 0.10;
    }

    if (directionChanges <= 2) {
      risk += 0.30;
    } else if (directionChanges <= 4) {
      risk += 0.15;
    }

    if (intersections == 0) {
      risk += 0.20;
    } else if (intersections == 1) {
      risk += 0.10;
    }

    if (overlaps == 0) risk += 0.10;
    if (isSymmetrical) risk += 0.15;

    risk = risk.clamp(0.0, 1.0);

    return AttackRisk(
      attackName: 'Smudge Attack',
      description: 'Attacker reads fingerprint residue on screen',
      level: _riskLevel(risk),
      score: risk,
      explanation: risk >= 0.5
          ? 'The stroke path is relatively clean and easier to reconstruct from residue traces.'
          : 'The pattern contains enough disruption to reduce trace readability.',
      mitigation: risk >= 0.5
          ? 'Use more turning points, crossings, or retraced strokes to obscure residue traces.'
          : 'Good smudge resistance. Cleaning the screen still helps.',
    );
  }

  static AttackRisk _calcDictionaryRisk({
    required bool isCommonPattern,
    required bool isSymmetrical,
    required bool biasedStart,
    required int nodeCount,
    required double entropy,
  }) {
    double risk = 0.0;
    final List<String> factors = <String>[];

    if (isCommonPattern) {
      risk += 0.60;
      factors.add('matches a known common pattern');
    }

    if (biasedStart) {
      risk += 0.20;
      factors.add('starts from a statistically overused node');
    }

    if (isSymmetrical) {
      risk += 0.10;
      factors.add('has visual symmetry');
    }

    if (nodeCount <= 5) {
      risk += 0.10;
      factors.add('uses few nodes');
    }

    if (entropy < 0.5) {
      factors.add('has low transition entropy');
    }

    risk = risk.clamp(0.0, 1.0);

    return AttackRisk(
      attackName: 'Dictionary Attack',
      description: 'Attacker tries commonly-used patterns first',
      level: _riskLevel(risk),
      score: risk,
      explanation: factors.isEmpty
          ? 'The pattern does not strongly resemble common user-selected shapes.'
          : 'The pattern is more guessable because it ${factors.join(', ')}.',
      mitigation: risk >= 0.4
          ? 'Avoid letter-like shapes, common lines, and predictable start points.'
          : 'Good uniqueness. Keep using less recognisable structures.',
    );
  }

  static AttackRisk _calcBruteForceRisk({
    required int nodeCount,
    required int directionChanges,
    required int intersections,
    required bool isCommonPattern,
  }) {
    double risk = 1.0;

    risk -= nodeCount * 0.06;
    risk -= directionChanges * 0.04;
    risk -= intersections * 0.05;

    if (isCommonPattern) {
      risk += 0.20;
    }

    risk = risk.clamp(0.0, 1.0);

    return AttackRisk(
      attackName: 'Brute-Force Attack',
      description: 'Attacker systematically tries all combinations',
      level: _riskLevel(risk),
      score: risk,
      explanation: nodeCount < 6
          ? 'Shorter patterns reduce the effective search space.'
          : 'The pattern uses enough structural complexity to better resist exhaustive guessing.',
      mitigation: nodeCount < 7
          ? 'Use 7 or more nodes and avoid simple layouts.'
          : 'Good brute-force resistance. Maintain strong complexity.',
    );
  }

  // =========================
  // Thermal attack risk
  // =========================

  /// Thermal (heat-signature) attack: an infrared camera photographs the screen
  /// immediately after authentication. Touched nodes retain residual heat for
  /// several seconds, revealing which grid positions were used.
  /// Key factors: fewer nodes → fewer distinct hot spots;
  ///              overlaps → ambiguous heat (makes reconstruction harder);
  ///              node count AND spatial spread combine to aid reconstruction.
  static AttackRisk _calcThermalRisk({
    required int nodeCount,
    required int overlaps,
    required double physicalLength,
    required bool isSymmetrical,
    required int directionChanges,
    required int intersections,
  }) {
    // Base risk: fewer nodes → clearer individual heat spots.
    // 4 nodes → 0.85, 5 → 0.72, 6 → 0.59, 7 → 0.46, 8 → 0.33, 9 → 0.20
    double risk = 0.85 - ((nodeCount - 4) * 0.13);
    risk = risk.clamp(0.15, 0.85);

    // Overlaps (retraced edges) create ambiguous heat intensity per node.
    // Strong impact: each overlap significantly confuses thermal readings.
    risk -= (overlaps * 0.12).clamp(0.0, 0.35);

    // Intersections produce confused heat zones where paths cross.
    risk -= (intersections * 0.10).clamp(0.0, 0.25);

    // Direction changes scatter heat across different grid regions.
    risk -= ((directionChanges / 6.0) * 0.18).clamp(0.0, 0.18);

    // Concentrated paths (short length) confuse heat more than spread ones.
    if (physicalLength > 10.0) {
      risk += 0.04;
    } else if (physicalLength < 5.0) {
      risk -= 0.08;
    }

    if (isSymmetrical) risk += 0.05;

    risk = risk.clamp(0.0, 1.0);

    final bool highRisk = risk >= 0.50;
    return AttackRisk(
      attackName: 'Thermal Attack',
      description: 'Infrared camera detects heat from recently touched nodes',
      level: _riskLevel(risk),
      score: risk,
      explanation: highRisk
          ? 'The pattern touches few distinct nodes with minimal heat overlap, '
          'making residual thermal signatures easy to distinguish and read.'
          : 'Sufficient node count, overlaps, or crossings make thermal '
          'reconstruction ambiguous — an attacker cannot reliably determine '
          'node order from heat alone.',
      mitigation: highRisk
          ? 'Use 7+ nodes and include retraced segments to create overlapping '
          'heat signatures that obscure the touched-node pattern.'
          : 'Good thermal resistance. Unlocking in warm or lit environments '
          'further reduces thermal readability.',
    );
  }

  // =========================
  // Pattern space & time estimate
  // =========================

  // Total valid Android patterns per node count (from Sun et al. 2014 / Uellenbeck et al.)
  static const Map<int, int> _patternCounts = {
    4: 1624,
    5: 7152,
    6: 26016,
    7: 72912,
    8: 140704,
    9: 140704,
  };

  static int _getSearchSpace(int nodeCount) =>
      _patternCounts[nodeCount.clamp(4, 9)] ?? 1624;

  /// Reduce total search space by behavioural biases documented in the
  /// literature (biased start node, symmetry, entropy).
  static int _getEffectiveSpace(
      int searchSpace, {
        required bool biasedStart,
        required bool isSymmetrical,
        required double entropy,
      }) {
    double factor = 1.0;
    // ~60% of users start from top-left 4 nodes → effective space shrinks significantly
    if (biasedStart) factor *= 0.40;
    if (isSymmetrical) factor *= 0.80;
    if (entropy < 0.40) factor *= 0.80;
    return (searchSpace * factor).round().clamp(1, searchSpace);
  }

  /// Estimated crack time **in hours** assuming Android's lockout schedule:
  /// 5 failed attempts → 30 s wait, repeated indefinitely.
  /// Effective rate ≈ 10 guesses / minute.
  static double _getCrackTimeHours(int effectiveSpace) {
    const double guessesPerMinute = 10.0;
    final double minutes = effectiveSpace / guessesPerMinute;
    return minutes / 60.0;
  }

  // =========================
  // Improvement suggestions
  // =========================

  static List<String> _generateImprovements({
    required int nodeCount,
    required int directionChanges,
    required int intersections,
    required int overlaps,
    required bool biasedStart,
    required bool isSymmetrical,
    required bool isBlocklisted,
    required double entropy,
  }) {
    final List<String> tips = <String>[];

    if (isBlocklisted) {
      tips.add(
        'Your pattern matches a known weak shape. Choose a completely different pattern.',
      );
    }

    if (nodeCount < 6) {
      tips.add('Use at least 6 nodes to increase the search space.');
    }

    if (directionChanges < 3) {
      tips.add('Add more directional turns to resist shoulder surfing.');
    }

    if (intersections == 0) {
      tips.add(
        'Include at least one crossing stroke to make visual reconstruction harder.',
      );
    }

    if (overlaps == 0) {
      tips.add(
        'Add at least one retraced segment to make residue traces less clean.',
      );
    }

    if (biasedStart) {
      tips.add(
        'Avoid starting from the top-left area because users often begin there.',
      );
    }

    if (isSymmetrical) {
      tips.add(
        'Break the visual symmetry. Symmetrical patterns are easier to predict.',
      );
    }

    if (entropy < 0.4) {
      tips.add(
        'Pattern transitions are repetitive. Mix your movement directions more.',
      );
    }

    if (tips.isEmpty) {
      tips.add(
        'Excellent pattern. Keep using unpredictable shapes with mixed directions.',
      );
    }

    return tips;
  }

  // =========================
  // Composite score
  // =========================

  static double _calcCompositeScore({
    required int nodeCount,
    required double length,
    required int intersections,
    required int overlaps,
    required int directionChanges,
    required double entropy,
    required bool biasedStart,
    required bool isSymmetrical,
    required bool passesValidation,
  }) {
    if (!passesValidation) return 0.0;

    // Report base formula:
    // Raw = (Sp × Lp) + (2 × Ip) + (2 × Op)
    final double rawScore =
        (nodeCount * length) + (2 * intersections) + (2 * overlaps);

    // Normalize raw score
    double normalized = (rawScore / 130.0).clamp(0.0, 1.0);

    // Small bonuses only
    normalized += (directionChanges / 8.0) * 0.05;
    normalized += entropy * 0.05;

    // Stronger penalties so obvious 9-node patterns do not auto-win
    double penalty = 0.0;

    if (biasedStart) penalty += 0.10;
    if (isSymmetrical) penalty += 0.20;

    if (directionChanges <= 2) {
      penalty += 0.20;
    } else if (directionChanges <= 4) {
      penalty += 0.10;
    }

    if (intersections == 0) {
      penalty += 0.15;
    } else if (intersections == 1) {
      penalty += 0.08;
    }

    if (entropy < 0.40) {
      penalty += 0.15;
    } else if (entropy < 0.60) {
      penalty += 0.08;
    }

    normalized -= penalty;
    normalized = normalized.clamp(0.0, 1.0);

    final double displayScore = (normalized * 10).clamp(1.0, 10.0);
    return double.parse(displayScore.toStringAsFixed(1));
  }

  // =========================
  // Main analysis
  // =========================

  static PatternAnalysisResult analyze(List<int> rawPattern) {
    final List<int> pattern = _insertIntermediates(rawPattern);

    // Gatekeeper
    if (pattern.length < 4) {
      return _rejectedResult(
        pattern: pattern,
        reason: 'Too short — connect at least 4 nodes.',
      );
    }

    final String? blockedName = CommonPatterns.matchName(pattern);
    final bool isCommonPattern = CommonPatterns.isBlocked(pattern);

    if (isCommonPattern) {
      final String suffix = blockedName != null ? ' ($blockedName)' : '';
      return _rejectedResult(
        pattern: pattern,
        reason:
        'This pattern$suffix is too common and easily guessed. Try something more unique.',
      );
    }

    // Metrics
    final int nodeCount = pattern.length;
    final double length = _calcLength(pattern);
    final int intersections = _calcIntersections(pattern);
    final int overlaps = _calcOverlaps(pattern);
    final int directionChanges = _calcDirectionChanges(pattern);
    final double entropy = _calcEntropy(pattern);
    final bool biasedStart =
        pattern.isNotEmpty && _biasedStartNodes.contains(pattern.first);
    final bool isSymmetrical = _isSymmetrical(pattern);

    // Score
    final double compositeScore = _calcCompositeScore(
      nodeCount: nodeCount,
      length: length,
      intersections: intersections,
      overlaps: overlaps,
      directionChanges: directionChanges,
      entropy: entropy,
      biasedStart: biasedStart,
      isSymmetrical: isSymmetrical,
      passesValidation: true,
    );

    // Risks
    final AttackRisk shoulderSurfRisk = _calcShoulderSurfRisk(
      nodeCount: nodeCount,
      directionChanges: directionChanges,
      intersections: intersections,
      isSymmetrical: isSymmetrical,
      isCommonPattern: isCommonPattern,
    );

    final AttackRisk smudgeRisk = _calcSmudgeRisk(
      nodeCount: nodeCount,
      directionChanges: directionChanges,
      intersections: intersections,
      overlaps: overlaps,
      isSymmetrical: isSymmetrical,
    );

    final AttackRisk dictionaryRisk = _calcDictionaryRisk(
      isCommonPattern: isCommonPattern,
      isSymmetrical: isSymmetrical,
      biasedStart: biasedStart,
      nodeCount: nodeCount,
      entropy: entropy,
    );

    final AttackRisk bruteForceRisk = _calcBruteForceRisk(
      nodeCount: nodeCount,
      directionChanges: directionChanges,
      intersections: intersections,
      isCommonPattern: isCommonPattern,
    );

    final AttackRisk thermalRisk = _calcThermalRisk(
      nodeCount: nodeCount,
      overlaps: overlaps,
      physicalLength: length,
      isSymmetrical: isSymmetrical,
      directionChanges: directionChanges,
      intersections: intersections,
    );

    // Pattern space
    final int searchSpace = _getSearchSpace(nodeCount);
    final int effectiveSpace = _getEffectiveSpace(
      searchSpace,
      biasedStart: biasedStart,
      isSymmetrical: isSymmetrical,
      entropy: entropy,
    );
    final double crackHours = _getCrackTimeHours(effectiveSpace);

    // Base classification (7-tier)
    StrengthCategory strength;
    if (compositeScore < 1.5) {
      strength = StrengthCategory.weakest;
    } else if (compositeScore < 3.5) {
      strength = StrengthCategory.weak;
    } else if (compositeScore < 5.0) {
      strength = StrengthCategory.weakToMedium;
    } else if (compositeScore < 6.5) {
      strength = StrengthCategory.medium;
    } else if (compositeScore < 7.5) {
      strength = StrengthCategory.mediumToStrong;
    } else if (compositeScore < 9.0) {
      strength = StrengthCategory.strong;
    } else {
      strength = StrengthCategory.strongest;
    }

    // Downgrade rules for visually predictable patterns (drop one tier)
    if (strength.index >= StrengthCategory.mediumToStrong.index) {
      if (isSymmetrical ||
          (biasedStart && intersections == 0) ||
          directionChanges <= 2 ||
          entropy < 0.40) {
        strength = StrengthCategory.values[strength.index - 1];
      }
    }

    final List<String> improvements = _generateImprovements(
      nodeCount: nodeCount,
      directionChanges: directionChanges,
      intersections: intersections,
      overlaps: overlaps,
      biasedStart: biasedStart,
      isSymmetrical: isSymmetrical,
      isBlocklisted: isCommonPattern,
      entropy: entropy,
    );

    return PatternAnalysisResult(
      pattern: pattern,
      passesValidation: true,
      nodeCount: nodeCount,
      physicalLength: length,
      intersections: intersections,
      overlaps: overlaps,
      directionChanges: directionChanges,
      entropy: entropy,
      hasTopLeftStart: biasedStart,
      isInBlocklist: isCommonPattern,
      isSymmetrical: isSymmetrical,
      compositeScore: compositeScore,
      shoulderSurfRisk: shoulderSurfRisk,
      smudgeRisk: smudgeRisk,
      dictionaryRisk: dictionaryRisk,
      bruteForceRisk: bruteForceRisk,
      thermalRisk: thermalRisk,
      patternSearchSpace: searchSpace,
      effectiveSearchSpace: effectiveSpace,
      timeToCrackHours: crackHours,
      strength: strength,
      improvements: improvements,
    );
  }

  static PatternAnalysisResult _rejectedResult({
    required List<int> pattern,
    required String reason,
  }) {
    final AttackRisk dummyRisk = AttackRisk(
      attackName: '',
      description: '',
      level: RiskLevel.critical,
      score: 1.0,
      explanation: '',
      mitigation: '',
    );

    return PatternAnalysisResult(
      pattern: pattern,
      passesValidation: false,
      validationFailReason: reason,
      nodeCount: pattern.length,
      physicalLength: 0.0,
      intersections: 0,
      overlaps: 0,
      directionChanges: 0,
      entropy: 0.0,
      hasTopLeftStart: pattern.isNotEmpty && pattern.first <= 3,
      isInBlocklist: true,
      isSymmetrical: false,
      compositeScore: 0.0,
      shoulderSurfRisk: dummyRisk,
      smudgeRisk: dummyRisk,
      dictionaryRisk: dummyRisk,
      bruteForceRisk: dummyRisk,
      thermalRisk: dummyRisk,
      patternSearchSpace: 0,
      effectiveSearchSpace: 0,
      timeToCrackHours: 0.0,
      strength: StrengthCategory.weak,
      improvements: <String>[reason],
    );
  }
}