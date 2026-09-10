import 'dart:math';

/// Generic wake-up challenge abstraction.
///
/// Existing Questions challenge is migrated onto this interface without UX
/// change; Math / Memory / Shake / Random implement the same contract so the
/// alarm screen can host any of them interchangeably:
///
/// ```text
/// WakeUpChallenge
/// ├── QuestionChallenge
/// ├── MathChallenge
/// ├── MemoryChallenge
/// └── ShakeChallenge
/// ```
enum ChallengeType { questions, math, memory, shake, random }

enum ChallengeDifficulty { easy, medium, hard }

/// Allowed question counts (spec: 1/3/5/7/10 — never force 10).
const allowedQuestionCounts = [1, 3, 5, 7, 10];

abstract class WakeUpChallenge {
  ChallengeType get type;
  ChallengeDifficulty get difficulty;
  int get targetCount;
  int get completedCount;
  double get progress =>
      targetCount <= 0 ? 0 : (completedCount / targetCount).clamp(0.0, 1.0);
  bool get isCompleted => completedCount >= targetCount;
  void start();
  void reset();
}

/// Difficulty-scaled question-count helper (kept trivial on purpose).
int targetForDifficulty(ChallengeDifficulty d, int baseCount) {
  final clamped = allowedQuestionCounts.contains(baseCount)
      ? baseCount
      : (baseCount.clamp(1, 10));
  return clamped;
}

// ---------------------------------------------------------------------------
// Math challenge: dynamically generated, offline, no repeats in a session.
// ---------------------------------------------------------------------------

class MathQuestion {
  final String prompt;
  final int answer;
  const MathQuestion(this.prompt, this.answer);
}

class MathChallenge extends WakeUpChallenge {
  @override
  final ChallengeType type = ChallengeType.math;
  @override
  final ChallengeDifficulty difficulty;
  @override
  final int targetCount;
  int _done = 0;
  final Random _rng;
  MathQuestion? current;
  final Set<String> _seen = {};

  MathChallenge({
    this.difficulty = ChallengeDifficulty.medium,
    int questionCount = 3,
    Random? rng,
  })  : targetCount = targetForDifficulty(difficulty, questionCount),
        _rng = rng ?? Random();

  @override
  int get completedCount => _done;

  @override
  void start() {
    reset();
    next();
  }

  @override
  void reset() {
    _done = 0;
    _seen.clear();
    current = null;
  }

  /// Generates the next unique question for the difficulty.
  MathQuestion next() {
    for (var i = 0; i < 50; i++) {
      final q = _generate();
      if (_seen.add(q.prompt)) {
        current = q;
        return q;
      }
    }
    final q = _generate();
    current = q;
    return q;
  }

  /// Returns true on correct answer (advances), false on wrong (retry same).
  bool answer(int value) {
    final q = current;
    if (q == null || isCompleted) return false;
    if (value == q.answer) {
      _done++;
      if (!isCompleted) next();
      return true;
    }
    return false;
  }

  MathQuestion _generate() {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        final a = 2 + _rng.nextInt(18); // 2..19
        final b = 2 + _rng.nextInt(18);
        final add = _rng.nextBool();
        return add
            ? MathQuestion('$a + $b = ؟', a + b)
            : MathQuestion('${max(a, b)} − ${min(a, b)} = ؟', (a - b).abs());
      case ChallengeDifficulty.medium:
        if (_rng.nextBool()) {
          final a = 6 + _rng.nextInt(14); // 6..19
          final b = 3 + _rng.nextInt(9); // 3..11
          return MathQuestion('$a × $b = ؟', a * b);
        }
        final b = 2 + _rng.nextInt(18);
        final ans = 2 + _rng.nextInt(18);
        return MathQuestion('${b * ans} ÷ $b = ؟', ans);
      case ChallengeDifficulty.hard:
        final b = 2 + _rng.nextInt(10); // 2..11
        final ans = 3 + _rng.nextInt(20);
        final c = 5 + _rng.nextInt(30);
        return MathQuestion('${b * ans} ÷ $b + $c = ؟', ans + c);
    }
  }
}

// ---------------------------------------------------------------------------
// Memory challenge state machine (UI renders tiles; this owns matching).
// ---------------------------------------------------------------------------

class MemoryChallenge extends WakeUpChallenge {
  @override
  final ChallengeType type = ChallengeType.memory;
  @override
  final ChallengeDifficulty difficulty;
  @override
  int get targetCount => pairs;
  final int pairs;
  final List<int> tiles;
  final Set<int> matched = {};
  int? _first;
  int _matchedPairs = 0;

  MemoryChallenge({this.pairs = 4, this.difficulty = ChallengeDifficulty.medium, Random? rng})
      : tiles = _shuffled(pairs, rng ?? Random());

  static List<int> _shuffled(int pairs, Random rng) {
    final t = [for (var i = 0; i < pairs; i++) ...[i, i]];
    t.shuffle(rng);
    return t;
  }

  @override
  int get completedCount => _matchedPairs;

  @override
  void start() => reset();

  @override
  void reset() {
    matched.clear();
    _first = null;
    _matchedPairs = 0;
  }

  /// Flip result: 0 = first pick, 1 = match, 2 = mismatch, 3 = already done.
  int flip(int index) {
    if (matched.contains(index) || isCompleted) return 3;
    if (_first == null) {
      _first = index;
      return 0;
    }
    final f = _first!;
    _first = null;
    if (f != index && tiles[f] == tiles[index]) {
      matched.addAll([f, index]);
      _matchedPairs++;
      return 1;
    }
    return 2;
  }
}

// ---------------------------------------------------------------------------
// Shake challenge accumulator (sensor layer feeds [addShake]).
// ---------------------------------------------------------------------------

class ShakeChallenge extends WakeUpChallenge {
  @override
  final ChallengeType type = ChallengeType.shake;
  @override
  final ChallengeDifficulty difficulty;
  @override
  final int targetCount;
  int _progress = 0;

  ShakeChallenge({this.difficulty = ChallengeDifficulty.medium, this.targetCount = 100});

  void addShake({int amount = 10}) {
    if (!isCompleted) _progress = min(targetCount, _progress + amount);
  }

  @override
  int get completedCount => _progress;

  @override
  void start() => reset();

  @override
  void reset() => _progress = 0;
}

/// Random picker: chooses from the *enabled* challenge list only.
ChallengeType pickRandomChallenge(List<ChallengeType> enabled, {Random? rng}) {
  final pool = enabled.where((c) => c != ChallengeType.random).toList();
  if (pool.isEmpty) return ChallengeType.questions;
  pool.shuffle(rng ?? Random());
  return pool.first;
}

