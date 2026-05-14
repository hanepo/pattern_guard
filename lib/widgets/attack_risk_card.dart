import 'package:flutter/material.dart';
import '../models/pattern_model.dart';
import '../utils/app_theme.dart';

class AttackRiskCard extends StatefulWidget {
  final AttackRisk risk;

  const AttackRiskCard({super.key, required this.risk});

  @override
  State<AttackRiskCard> createState() => _AttackRiskCardState();
}

class _AttackRiskCardState extends State<AttackRiskCard> {
  bool _expanded = false;

  Color get _riskColor {
    switch (widget.risk.level) {
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

  IconData get _attackIcon {
    switch (widget.risk.attackName) {
      case 'Shoulder Surfing':
        return Icons.visibility_outlined;
      case 'Smudge Attack':
        return Icons.fingerprint;
      case 'Dictionary Attack':
        return Icons.menu_book_outlined;
      case 'Brute-Force Attack':
        return Icons.bolt_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expanded ? _riskColor.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_attackIcon, color: _riskColor, size: 18),
                ),
                const SizedBox(width: 12),
                // Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.risk.attackName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        widget.risk.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Risk badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _RiskBadge(level: widget.risk.level, color: _riskColor),
                    const SizedBox(height: 4),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppTheme.textHint,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
            // Vulnerability bar
            const SizedBox(height: 10),
            _VulnBar(score: widget.risk.score, color: _riskColor),
            // Expanded details
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.info_outline,
                label: 'Analysis',
                text: widget.risk.explanation,
                color: _riskColor,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.lightbulb_outline,
                label: 'Mitigation',
                text: widget.risk.mitigation,
                color: AppTheme.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final Color color;

  const _RiskBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _VulnBar extends StatelessWidget {
  final double score; // 0–1
  final Color color;

  const _VulnBar({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vulnerability',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textHint,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 4,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
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
    );
  }
}