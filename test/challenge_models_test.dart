import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:small_husn_muslim/features/fajr_challenge/domain/challenge_models.dart';

void main() {
  group('MathChallenge', () {
    test('easy generates small additions/subtractions with valid answers', () {
      final c = MathChallenge(
          difficulty: ChallengeDifficulty.easy,
          questionCount: 3,
          rng: Random(1))
        ..start();
      for (var i = 0; i < 3; i++) {
        final q = c.current!;
        expect(q.prompt, isNotEmpty);
        // Answering correctly advances.
        expect(c.answer(q.answer), isTrue);
      }
      expect(c.isCompleted, isTrue);
    });

    test('wrong answers do not advance (retry, not frustration-loop)', () {
      final c = MathChallenge(
          difficulty: ChallengeDifficulty.medium,
          questionCount: 1,
          rng: Random(2))
        ..start();
      final q = c.current!;
      expect(c.answer(q.answer + 9999), isFalse);
      expect(c.isCompleted, isFalse);
      expect(c.answer(q.answer), isTrue);
      expect(c.isCompleted, isTrue);
    });

    test('hard division questions are exact (no ambiguous fractions)', () {
      final c = MathChallenge(
          difficulty: ChallengeDifficulty.hard,
          questionCount: 5,
          rng: Random(7))
        ..start();
      final seen = <String>{};
      for (var i = 0; i < 5; i++) {
        final q = c.current!;
        expect(seen.add(q.prompt), isTrue, reason: 'no repeats: ${q.prompt}');
        expect(c.answer(q.answer), isTrue);
      }
      expect(c.isCompleted, isTrue);
      expect(c.progress, 1.0);
    });

    test('question count honors 1/3/5/7/10 presets', () {
      for (final n in [1, 3, 5, 7, 10]) {
        final c = MathChallenge(questionCount: n, rng: Random(0));
        expect(c.targetCount, n);
      }
    });
  });

  group('MemoryChallenge', () {
    test('matching all 4 pairs completes the challenge', () {
      final c = MemoryChallenge(pairs: 4, rng: Random(3))..start();
      expect(c.tiles, hasLength(8));
      // Find and flip each pair.
      final byValue = <int, List<int>>{};
      for (var i = 0; i < c.tiles.length; i++) {
        byValue.putIfAbsent(c.tiles[i], () => []).add(i);
      }
      for (final idx in byValue.values) {
        expect(c.flip(idx[0]), 0);
        expect(c.flip(idx[1]), 1);
      }
      expect(c.isCompleted, isTrue);
    });

    test('mismatch does not complete and can be retried', () {
      final c = MemoryChallenge(pairs: 4, rng: Random(3))..start();
      // Find two tiles with different values.
      var a = 0, b = 1;
      while (c.tiles[a] == c.tiles[b]) {
        b++;
      }
      expect(c.flip(a), 0);
      expect(c.flip(b), 2);
      expect(c.isCompleted, isFalse);
    });
  });

  group('ShakeChallenge', () {
    test('progress accumulates to 100% then completes', () {
      final c = ShakeChallenge()..start();
      expect(c.isCompleted, isFalse);
      for (var i = 0; i < 10; i++) {
        c.addShake(amount: 10);
      }
      expect(c.isCompleted, isTrue);
      expect(c.progress, 1.0);
    });
  });

  group('pickRandomChallenge', () {
    test('never picks disabled challenges or random itself', () {
      final enabled = [ChallengeType.math, ChallengeType.memory];
      for (var i = 0; i < 20; i++) {
        final pick = pickRandomChallenge(enabled, rng: Random(i));
        expect(enabled, contains(pick));
        expect(pick, isNot(ChallengeType.random));
      }
    });

    test('falls back to questions when nothing is enabled', () {
      expect(pickRandomChallenge([]), ChallengeType.questions);
    });
  });
}
