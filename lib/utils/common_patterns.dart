// common_patterns.dart
// ─────────────────────────────────────────────────────────────────────────────
// Grid reference (node numbers):
//   0 | 1 | 2
//   3 | 4 | 5
//   6 | 7 | 8
//
// Every pattern here is SO common it must NEVER reach the score calculator.
// Source: Sun et al. (2014), Andriotis et al., real-world leaks & studies.
// ─────────────────────────────────────────────────────────────────────────────

class CommonPatterns {
  // Returns true if the given pattern (exact node sequence) is blocked.
  static bool isBlocked(List<int> pattern) {
    final key = pattern.join(',');
    // Check forward and reverse
    final keyRev = pattern.reversed.toList().join(',');
    for (final blocked in _all) {
      if (blocked == key || blocked == keyRev) return true;
    }
    return false;
  }

  // Returns the human-readable name of the matched pattern, or null.
  static String? matchName(List<int> pattern) {
    final key = pattern.join(',');
    final keyRev = pattern.reversed.toList().join(',');
    for (final entry in _named.entries) {
      if (entry.value == key || entry.value == keyRev) return entry.key;
    }
    return null;
  }

  // ── Named patterns (shown in rejection message) ──────────────────────────
  static final Map<String, String> _named = {
    // ── Letters ──────────────────────────────────────────────────────────
    'letter L':       '0,3,6,7,8',
    'letter L (flip)':'2,5,8,7,6',
    'letter L (top)': '0,1,2,5,8',
    'letter L (top-flip)': '2,1,0,3,6',
    'letter Z':       '0,1,2,5,3,6,7,8',
    'letter Z (alt)': '0,1,2,4,6,7,8',
    'letter Z (small)':'0,1,2,4,3',
    'letter N':       '0,3,6,4,2,5,8',
    'letter N (mirror)':'2,5,8,4,0,3,6',
    'letter U':       '0,3,6,7,8,5,2',
    'letter U (mirror)':'2,5,8,7,6,3,0',
    'letter C':       '2,1,0,3,6,7,8',
    'letter C (mirror)':'0,1,2,5,8,7,6',
    'letter S':       '2,1,0,3,4,5,8,7,6',
    'letter S (alt)': '0,1,2,4,6,7,8',
    'letter V':       '0,3,7,5,2',   // 0,3,7,5,2  (V shape)
    'letter M':       '0,3,4,5,2',
    'letter W':       '0,6,4,8,2',
    'letter T':       '0,1,2,4,7',
    'letter T (alt)': '1,4,7',
    'letter X':       '0,4,8,2,4,6',
    'letter G':       '2,1,0,3,6,7,8,5,4',
    'letter O (square)': '0,1,2,5,8,7,6,3,0',

    // ── Straight lines ────────────────────────────────────────────────────
    'top row':        '0,1,2',
    'middle row':     '3,4,5',
    'bottom row':     '6,7,8',
    'left column':    '0,3,6',
    'middle column':  '1,4,7',
    'right column':   '2,5,8',
    'main diagonal':  '0,4,8',
    'anti-diagonal':  '2,4,6',

    // ── Short straights (4 nodes) ─────────────────────────────────────────
    'top-left 4':     '0,1,2,5',
    'bottom-left 4':  '6,7,8,5',
    'top-right 4':    '2,1,0,3',
    'bottom-right 4': '8,7,6,3',

    // ── Simple squares ────────────────────────────────────────────────────
    'square (full)':  '0,1,2,5,8,7,6,3',
    'square (top-left)': '0,1,4,3',
    'square (top-right)': '1,2,5,4',
    'square (bot-left)':  '3,4,7,6',
    'square (bot-right)': '4,5,8,7',

    // ── Crosses / plus ────────────────────────────────────────────────────
    'plus sign':      '1,4,7,4,3,4,5',
    'cross':          '0,4,8',

    // ── Corners / hooks ───────────────────────────────────────────────────
    'hook top-left':  '2,1,0,3,6',
    'hook top-right': '0,1,2,5,8',
    'hook bot-left':  '2,5,8,7,6',
    'hook bot-right': '0,3,6,7,8',

    // ── Zigzags ───────────────────────────────────────────────────────────
    'zigzag top':     '0,1,2,5,4,3,6,7,8',
    'zigzag side':    '0,3,6,7,4,1,2,5,8',

    // ── Full sweeps ───────────────────────────────────────────────────────
    'full sequential':'0,1,2,3,4,5,6,7,8',
    'full reverse':   '8,7,6,5,4,3,2,1,0',
    'spiral in':      '0,1,2,5,8,7,6,3,4',
    'spiral out':     '4,3,6,7,8,5,2,1,0',
    'snake row':      '0,1,2,5,4,3,6,7,8',
    'snake col':      '0,3,6,7,4,1,2,5,8',

    // ── Arrows ───────────────────────────────────────────────────────────
    'arrow right':    '0,3,4,5,2',
    'arrow left':     '2,5,4,3,0',
    'arrow up':       '6,4,2',     // diagonal arrow
    'arrow down':     '0,4,8',

    // ── Very short (4-node) commons ───────────────────────────────────────
    '4-node top-left corner':  '0,1,3,4',
    '4-node top-right corner': '1,2,4,5',
    '4-node bot-left corner':  '3,4,6,7',
    '4-node bot-right corner': '4,5,7,8',
    '4-node diagonal':         '0,4,8,5',
    '4-node reverse diagonal': '2,4,6,3',

    // ── Star / asterisk (common decorative) ──────────────────────────────
    'star':           '1,5,6,2,7,0,4',
    'asterisk center':'4,0,4,2,4,6,4,8',
  };

  // ── Full blocklist (all patterns as "a,b,c,..." strings) ─────────────────
  // Generated from _named + extra variants not worth naming individually.
  static final Set<String> _all = () {
    final s = <String>{};

    // Add all named patterns
    for (final v in _named.values) {
      s.add(v);
      // Also add reversed
      s.add(v.split(',').reversed.join(','));
    }

    // ── Extra raw patterns ────────────────────────────────────────────────

    // All straight rows/cols 4-node
    s.addAll(['0,1,2,3', '1,2,3,4', '3,4,5,6', '4,5,6,7',
      '0,3,4,1', '1,4,5,2', '3,6,7,4', '4,7,8,5']);

    // Single diagonal moves
    s.addAll(['0,4', '4,8', '2,4', '4,6',
      '0,4,8,7', '0,4,8,5', '2,4,6,7', '2,4,6,3']);

    // Short column subsets
    s.addAll(['0,3,6,7', '2,5,8,7', '0,1,4,7', '2,1,4,7']);

    // Common 5-node patterns
    s.addAll([
      '0,1,2,5,4', '0,1,4,5,8', '0,3,4,5,2',
      '2,5,4,3,6', '0,4,8,7,6', '2,4,6,3,0',
      '0,1,2,4,8', '2,1,0,4,6', '6,7,8,4,0',
      '0,3,6,4,2', '2,5,8,4,6', '6,3,0,4,8',
    ]);

    // Mirror/rotation variants of L
    s.addAll([
      '6,3,0,1,2', '8,5,2,1,0', '6,7,8,5,2',
      '0,1,2,5,8', '2,5,8,7,6', '8,7,6,3,0',
    ]);

    // N and its mirrors/rotations
    s.addAll([
      '0,3,6,4,2,5,8', '2,5,8,4,0,3,6',
      '0,1,2,4,8,7,6', '6,7,8,4,0,1,2',
    ]);

    // U shapes all 4 rotations
    s.addAll([
      '0,3,6,7,8,5,2',  // U
      '2,5,8,7,6,3,0',  // U mirror
      '0,1,2,5,8,7,6',  // C
      '6,7,8,5,2,1,0',  // C flip
    ]);

    // Z shapes
    s.addAll([
      '0,1,2,5,3,6,7,8',
      '6,7,8,5,3,0,1,2',
      '0,3,6,4,2,5,8',
      '2,5,8,4,6,3,0',
    ]);

    // Simple 4-node lines in all directions
    for (final start in [0,1,2,3,4,5,6,7,8]) {
      // horizontal
      final row = start ~/ 3;
      final col = start % 3;
      // right
      if (col + 3 <= 3) s.add('${row*3+col},${row*3+col+1},${row*3+col+2}');
      // down
      if (row + 3 <= 3) s.add('${row*3+col},${(row+1)*3+col},${(row+2)*3+col}');
    }

    return s;
  }();
}