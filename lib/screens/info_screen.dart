import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class InfoScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const InfoScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How It Works'),
        actions: [
          if (onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
              tooltip: 'Sign Out',
              onPressed: onLogout,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _InfoCard(
            icon: Icons.shield_outlined,
            title: 'Hybrid Evaluation Approach',
            color: AppTheme.accent,
            content:
            'This analyser uses a two-layer approach: first, rule-based validation blocks known weak patterns. '
                'Then, a composite score is calculated using weighted metrics that reflect real-world attack resistance.',
          ),
          SizedBox(height: 12),
          _SectionTitle(text: 'METRICS EXPLAINED'),
          SizedBox(height: 10),
          _InfoCard(
            icon: Icons.circle_outlined,
            title: 'Node Count (Sp)',
            color: AppTheme.riskMedium,
            content:
            'More distinct nodes expand the theoretical search space. '
                'Android allows 4–9 nodes. Patterns with 7+ nodes are significantly harder to brute-force.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.straighten,
            title: 'Physical Length (Lp)',
            color: AppTheme.riskMedium,
            content:
            'Total distance of the drawn path on the 3×3 grid. Longer paths require more '
                'motor precision, making them harder to reproduce from brief observation.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.swap_calls,
            title: 'Intersections (Ip)',
            color: AppTheme.riskLow,
            content:
            'When pattern segments cross each other, observers cannot determine '
                'the correct stroke order. Each intersection significantly reduces shoulder-surfing success.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.layers_outlined,
            title: 'Overlaps (Op)',
            color: AppTheme.riskLow,
            content:
            'Retracing a segment obscures the fingerprint smudge trail. '
                'Multiple strokes over the same path make smudge attack reconstruction infeasible.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.alt_route,
            title: 'Direction Changes',
            color: AppTheme.riskLow,
            content:
            'Sharp turns and irregular trajectories disrupt visual tracking. '
                'Cognitive studies show observers struggle to reconstruct patterns with 4+ direction changes.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.shuffle,
            title: 'Shannon Entropy',
            color: AppTheme.accent,
            content:
            'Measures unpredictability of node transitions using H = -Σ p log₂ p. '
                'High entropy means the pattern does not repeat predictable movement sequences.',
          ),
          SizedBox(height: 16),
          _SectionTitle(text: 'COMPOSITE SCORE FORMULA'),
          SizedBox(height: 10),
          _FormulaCard(),
          SizedBox(height: 16),
          _SectionTitle(text: 'ATTACK TYPES'),
          SizedBox(height: 10),
          _InfoCard(
            icon: Icons.visibility_outlined,
            title: 'Shoulder Surfing',
            color: AppTheme.riskHigh,
            content:
            'An attacker visually observes your pattern from nearby or via camera. '
                'Patterns with few direction changes and no crossings are trivially reconstructed this way.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.fingerprint,
            title: 'Smudge Attack',
            color: AppTheme.riskHigh,
            content:
            'Fingerprint residue on the screen reveals the pattern path. '
                'Attackers photograph the screen under angled light to extract the trail.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.menu_book_outlined,
            title: 'Dictionary Attack',
            color: AppTheme.riskCritical,
            content:
            'Research shows ~20% of users pick patterns resembling letters (L, Z, S). '
                'Attackers prioritise these common shapes first, drastically reducing guesses needed.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.bolt_outlined,
            title: 'Brute-Force Attack',
            color: AppTheme.riskMedium,
            content:
            'Android has 389,112 valid patterns. Short patterns (4 nodes = 1,624 possibilities) '
                'can be exhausted rapidly. 7-node patterns take ~50× longer to crack.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.thermostat_outlined,
            title: 'Thermal Attack',
            color: AppTheme.riskHigh,
            content:
            'Modern infrared cameras can capture heat signatures on a touchscreen within '
                'seconds of pattern entry. Touched nodes retain warmth (~0.5–3 s), revealing '
                'which grid positions were used. Overlapping strokes mix heat signals and '
                'make reconstruction significantly harder.',
          ),
          SizedBox(height: 8),
          _InfoCard(
            icon: Icons.thermostat_outlined,
            title: 'Thermal Attack',
            color: AppTheme.riskHigh,
            content:
            'Infrared cameras can detect residual heat from recently touched nodes '
                'immediately after authentication. An attacker photographing the screen '
                'within seconds can identify which grid positions were pressed. '
                'Patterns with few nodes and no retraced segments leave the clearest thermal signatures.',
          ),
          SizedBox(height: 24),
          _InfoCard(
            icon: Icons.school_outlined,
            title: 'References',
            color: AppTheme.textSecondary,
            content:
            '• Sun et al. (2014) — Pattern strength meters\n'
                '• Izadeen & Ameen (2021) — Graphical password strategies\n'
                '• Al-Qaraghuli & Hillier (2022) — Risk score for Android\n'
                '• Binbeshr et al. (2024) — Shoulder-surfing resistance\n'
                '• Kamba et al. (2025) — Usability vs security\n'
                '• Shingate et al. (2024) — Graphical password authentication',
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score = (Sp × Lp) + (2 × Ip) + (2 × Op) + (1.5 × Dir) + (10 × H)',
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: AppTheme.accent,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 8),
          _formulaRow('Sp', 'Number of distinct nodes'),
          _formulaRow('Lp', 'Physical path length on grid'),
          _formulaRow('Ip', 'Intersection count (×2 weight)'),
          _formulaRow('Op', 'Overlap count (×2 weight)'),
          _formulaRow('Dir', 'Direction changes (×1.5 weight)'),
          _formulaRow('H', 'Shannon entropy (×10 weight)'),
          const SizedBox(height: 6),
          const Text(
            'Based on Sun et al. (2014), extended with entropy and directional complexity.',
            style: TextStyle(fontSize: 10, color: AppTheme.textHint, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _formulaRow(String symbol, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            '— $description',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}