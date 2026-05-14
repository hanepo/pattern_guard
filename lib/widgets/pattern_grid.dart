import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pattern_model.dart';
import '../utils/app_theme.dart';
import '../utils/common_patterns.dart';
import '../utils/pattern_analyzer.dart';
import '../utils/sound_service.dart';

enum ReleaseResult { accepted, tooShort, blocked }

class PatternGrid extends StatefulWidget {
  final Function(List<int> pattern, PatternAnalysisResult? liveResult)
  onPatternChanged;
  final Function(List<int> pattern) onPatternComplete;
  final bool isEnabled;

  const PatternGrid({
    super.key,
    required this.onPatternChanged,
    required this.onPatternComplete,
    this.isEnabled = true,
  });

  @override
  State<PatternGrid> createState() => PatternGridState();
}

class PatternGridState extends State<PatternGrid>
    with TickerProviderStateMixin {
  List<int> _pattern = [];
  Offset? _currentPos;
  final double _nodeRadius = 20.0;
  bool _isDrawing = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  bool _isFadingOut = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  Color _lineColor = AppTheme.accent;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _pattern = [];
          _currentPos = null;
          _isDrawing = false;
          _isFadingOut = false;
          _lineColor = AppTheme.accent;
        });
        widget.onPatternChanged([], null);
      }
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void reset() {
    _fadeController.reset();
    _shakeController.reset();

    setState(() {
      _pattern = [];
      _currentPos = null;
      _isDrawing = false;
      _isFadingOut = false;
      _lineColor = AppTheme.accent;
    });

    widget.onPatternChanged([], null);
  }

  Offset _nodeCenter(int index, Size size) {
    final double cellW = size.width / 3;
    final double cellH = size.height / 3;
    final int col = index % 3;
    final int row = index ~/ 3;

    return Offset(
      cellW * col + cellW / 2,
      cellH * row + cellH / 2,
    );
  }

  int? _hitTest(Offset pos, Size size) {
    for (int i = 0; i < 9; i++) {
      final Offset center = _nodeCenter(i, size);
      if ((pos - center).distance < _nodeRadius * 1.5) {
        return i;
      }
    }
    return null;
  }

  final SoundService _sound = SoundService();

  void _lightTap() {
    HapticFeedback.selectionClick();
    _sound.playNodeTap();
  }

  void _dragConnect() {
    HapticFeedback.selectionClick();
    _sound.playDragConnect();
  }

  void _successTap() {
    HapticFeedback.mediumImpact();
  }

  void _warningBuzz() {
    HapticFeedback.heavyImpact();
    _sound.playCommonPatternAlert();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    if (!widget.isEnabled || _isFadingOut) return;

    final int? hit = _hitTest(details.localPosition, size);

    if (hit != null) {
      setState(() {
        _pattern = [hit];
        _currentPos = details.localPosition;
        _isDrawing = true;
        _lineColor = AppTheme.accent;
      });

      _lightTap();
      _notifyChange();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (!widget.isEnabled || !_isDrawing || _isFadingOut) return;

    setState(() {
      _currentPos = details.localPosition;
    });

    final int? hit = _hitTest(details.localPosition, size);

    if (hit != null && !_pattern.contains(hit)) {
      setState(() {
        _pattern.add(hit);
      });

      _dragConnect();
      _notifyChange();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.isEnabled || !_isDrawing) return;

    setState(() {
      _currentPos = null;
      _isDrawing = false;
    });

    if (_pattern.length < 4) {
      _triggerRejection(AppTheme.weakColor);
      return;
    }

    if (CommonPatterns.isBlocked(_pattern)) {
      _triggerRejection(AppTheme.riskHigh);
      return;
    }

    _successTap();
    widget.onPatternComplete(List<int>.from(_pattern));
  }

  void _triggerRejection(Color color) {
    _warningBuzz();

    setState(() {
      _lineColor = color;
      _isFadingOut = true;
    });

    _shakeController.forward(from: 0);
    _fadeController.forward(from: 0);

    widget.onPatternComplete(List<int>.from(_pattern));
  }

  void _notifyChange() {
    final PatternAnalysisResult? result = _pattern.length >= 2
        ? PatternAnalyzer.analyze(List<int>.from(_pattern))
        : null;

    widget.onPatternChanged(List<int>.from(_pattern), result);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final Size size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return GestureDetector(
          onPanStart: (details) => _handlePanStart(details, size),
          onPanUpdate: (details) => _handlePanUpdate(details, size),
          onPanEnd: _handlePanEnd,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseAnim,
              _fadeAnim,
              _shakeAnim,
            ]),
            builder: (ctx, _) {
              final double shakeOffset = _isFadingOut
                  ? sin(_shakeAnim.value * pi * 6) * 6.0
                  : 0.0;

              return Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: Opacity(
                  opacity: _isFadingOut ? _fadeAnim.value : 1.0,
                  child: CustomPaint(
                    painter: _PatternPainter(
                      pattern: _pattern,
                      currentPos: _currentPos,
                      nodeRadius: _nodeRadius,
                      pulseValue: _pulseAnim.value,
                      isDrawing: _isDrawing,
                      size: size,
                      lineColor: _lineColor,
                    ),
                    size: size,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> pattern;
  final Offset? currentPos;
  final double nodeRadius;
  final double pulseValue;
  final bool isDrawing;
  final Size size;
  final Color lineColor;

  _PatternPainter({
    required this.pattern,
    required this.currentPos,
    required this.nodeRadius,
    required this.pulseValue,
    required this.isDrawing,
    required this.size,
    required this.lineColor,
  });

  Offset _nodeCenter(int index) {
    final double cellW = size.width / 3;
    final double cellH = size.height / 3;
    final int col = index % 3;
    final int row = index ~/ 3;

    return Offset(
      cellW * col + cellW / 2,
      cellH * row + cellH / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = lineColor.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint glowPaint = Paint()
      ..color = lineColor.withOpacity(0.2)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (pattern.length >= 2) {
      final Path path = Path();
      path.moveTo(
        _nodeCenter(pattern[0]).dx,
        _nodeCenter(pattern[0]).dy,
      );

      for (int i = 1; i < pattern.length; i++) {
        path.lineTo(
          _nodeCenter(pattern[i]).dx,
          _nodeCenter(pattern[i]).dy,
        );
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }

    if (currentPos != null && pattern.isNotEmpty && isDrawing) {
      final Offset lastCenter = _nodeCenter(pattern.last);
      canvas.drawLine(lastCenter, currentPos!, glowPaint);
      canvas.drawLine(lastCenter, currentPos!, linePaint);
    }

    for (int i = 0; i < 9; i++) {
      final Offset center = _nodeCenter(i);
      final bool isSelected = pattern.contains(i);
      final bool isLast = pattern.isNotEmpty && pattern.last == i;

      final Paint ringPaint = Paint()
        ..color = isSelected ? lineColor.withOpacity(0.5) : AppTheme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, nodeRadius, ringPaint);

      if (!isSelected && !isDrawing) {
        final Paint pulsePaint = Paint()
          ..color = AppTheme.accent.withOpacity(0.07 * pulseValue)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(center, nodeRadius * pulseValue, pulsePaint);
      }

      final Paint dotPaint = Paint()
        ..color = isSelected ? lineColor : AppTheme.textHint
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, isSelected ? 8.0 : 5.0, dotPaint);

      if (isLast) {
        canvas.drawCircle(
          center,
          nodeRadius * 1.2,
          Paint()
            ..color = lineColor.withOpacity(0.2)
            ..style = PaintingStyle.fill,
        );

        canvas.drawCircle(
          center,
          8.0,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill,
        );
      }

      final TextPainter nodeLabel = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: isSelected
                ? lineColor.withOpacity(0.8)
                : AppTheme.textHint,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      nodeLabel.paint(
        canvas,
        Offset(
          center.dx - nodeLabel.width / 2,
          center.dy + nodeRadius + 4,
        ),
      );
    }

    for (int i = 0; i < pattern.length; i++) {
      final Offset center = _nodeCenter(pattern[i]);

      final TextPainter orderLabel = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: AppTheme.bg,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      orderLabel.paint(
        canvas,
        Offset(
          center.dx - orderLabel.width / 2,
          center.dy - orderLabel.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.currentPos != currentPos ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.lineColor != lineColor;
  }
}