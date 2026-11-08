# Recall: Smart Flashcards & Learning Companion
> **"Study smarter, remember longer."**  
> A Production-Grade Flutter MVP featuring the **SuperMemo SM-2 Spaced Repetition Algorithm**, **Dynamic Weakness Detection Radar**, and **Interactive 3D Card Physics**.

---

## 🎯 Executive Summary & Problem Statement

College students and self-learners spend hundreds of hours using passive note-taking or generic flashcard apps (Quizlet, Anki). However:
1. **Passive Review Causes Forgetting:** Without spaced repetition, students review material when it's either too fresh (wasting time) or already forgotten (forcing re-learning).
2. **Lack of Weakness Targeting:** Existing apps treat all flashcards equally. If a student understands 90% of a deck but struggles with 10% (e.g. subnetting or deadlocks), they are forced to repeat the entire deck.

**Recall** solves this using an offline-first mobile architecture powered by the mathematical **SuperMemo-2 (SM-2)** algorithm and proactive **Weakness Detection Radar**.

---

## 🧠 Algorithmic Foundation: SuperMemo SM-2

Recall implements the formal **SM-2 Spaced Repetition Algorithm** ([lib/core/algorithms/sm2_engine.dart](file:///E:/FLUTTER%20DART/lib/core/algorithms/sm2_engine.dart)):

### 1. Variables
* $q \in \{1, 3, 4, 5\}$: User recall rating (`Again` = 1, `Hard` = 3, `Good` = 4, `Easy` = 5).
* $EF$: Ease Factor (Difficulty multiplier, defaults to $2.5$, strictly $\ge 1.3$).
* $n$: Repetition number (consecutive successful reviews).
* $I$: Interval in days until next review.

### 2. Formulas
$$\text{EF}' = \text{EF} + \left(0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02)\right)$$

$$\text{Interval } I(n) = \begin{cases} 
1 \text{ day} & \text{if } q < 3 \text{ (Failed recall: resets } n = 0\text{)} \\
1 \text{ day} & \text{if } n = 0 \\
6 \text{ days} & \text{if } n = 1 \\
\text{round}(I_{n-1} \times \text{EF}) & \text{if } n > 1 
\end{cases}$$

---

## 🛡️ Weakness Detection Heuristic

Instead of relying on unstable or costly external AI APIs, Recall executes a deterministic local heuristic query:

```dart
bool get isWeakCard => 
    timesReviewed >= 2 && (failureRate >= 0.40 || easeFactor < 1.9);
```

Cards flagged by the **Weakness Radar** are highlighted in red, elevated to the dashboard, and routed to immediate targeted practice drills.

---

## 📂 Architecture & File Structure

```text
E:\FLUTTER DART\
├── pubspec.yaml                # Flutter project dependencies
├── analysis_options.yaml       # Strict Flutter linting rules
├── preview/
│   └── index.html              # Standalone 3D interactive web preview
├── test/
│   └── sm2_engine_test.dart    # Mathematical unit test suite for SM-2
└── lib/
    ├── main.dart               # App entrypoint & system overlays
    ├── app.dart                # Main navigation shell (4 tabs)
    ├── core/
    │   ├── theme/              # Design tokens (Colors, Typography, Theme)
    │   ├── algorithms/         # Pure Dart SM-2 Engine
    │   ├── models/             # Flashcard, Deck, Subject, ReviewLog
    │   ├── services/           # StudyRepository (State management & seed data)
    │   └── widgets/            # AppButton, AppBadge, EmptyStateView, ToastFeedback
    └── features/
        ├── dashboard/          # Daily readiness hero, streaks, quick metrics
        ├── deck/               # Deck list, deck detail, card editor modal
        ├── study/              # 3D Flip Card widget, 4-button SM-2 rating bar
        ├── quiz/               # Dynamic 4-option quiz with distractor engine
        └── analytics/          # Retention rate, SM-2 distribution, Weakness Radar
```

---

## 🚀 How to Run the Project

### Option A: Interactive Web Preview (Zero Setup Needed)
You can test the entire UI and SM-2 flow immediately in any browser:
1. Open File Explorer and navigate to `E:\FLUTTER DART\preview\`.
2. Double-click `index.html` to open it in Google Chrome or Edge.

### Option B: Running via Flutter CLI
Once Flutter is installed in your system PATH:

```powershell
# 1. Fetch dependencies
flutter pub get

# 2. Run unit tests
flutter test

# 3. Launch on Windows Desktop, Chrome, or connected Android phone
flutter run
```

---

## 🎤 Defense Q&A Cheatsheet (For Your Panelists)

| Panelist Question | Your Winning Answer |
| :--- | :--- |
| **"What makes this different from Quizlet or Anki?"** | *"Quizlet focuses mostly on linear card memorization without scientific decay intervals. Anki has spaced repetition but suffers from a steep 2000s desktop learning curve. Recall combines modern Material 3 mobile UX with automatic weakness radar and dynamic quiz simulations."* |
| **"What if the internet drops during the defense?"** | *"Recall is designed with a 100% offline-first architecture. All database models, review history, and SM-2 mathematical calculations run locally on the client device."* |
| **"Where is the AI component?"** | *"Rather than adding an expensive, unpredictable LLM wrapper, we implemented an algorithmic intelligence layer: the SM-2 adaptive memory model paired with heuristic failure rate clustering."* |
