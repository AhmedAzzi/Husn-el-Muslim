# CHALLENGE_ARCHITECTURE.md — generic wake-up challenge engine

```text
WakeUpChallenge (start/reset/handleInput/isCompleted/progress)
├── QuestionChallenge (legacy: dhikr→category MCQ + text input, in FajrChallengeScreen)
├── MathChallenge (Easy: +/− · Medium: ×/÷ · Hard: ÷ then +c; dynamic, no repeats)
├── MemoryChallenge (4 pairs/8 tiles state machine; UI flip with delay — next)
├── ShakeChallenge (accumulator; sensor feed — next)
└── RandomChallenge (pickRandomChallenge from enabled-only list)
```

- Difficulty is real: Easy/Medium/Hard change Math ranges and force text-input
  for Hard questions. Counts honor 1/3/5/7/10 (never force 10).
- Wrong answer → retry (snackbar), never a frustration loop or impossible item.
- Completion ≠ success: challenge done → stop alarm → "هل أنت مستيقظ؟"
  ("أنا مستيقظ") → Well Done → `FajrTrackingRepository.recordWakeUpSuccess()`.
  Opening the screen or starting the challenge records nothing.
