# 📱 COMPREHENSIVE PRD: "FutSwipe" (Football Swipe Game)

**Platform:** iOS & Android (Cross-platform)  
**Framework:** Flutter (Dart)  
**Genre:** High-Speed Arcade / Time Attack Trivia  
**Architecture:** Feature-First (or Clean Architecture)

## 1. App Overview & Vision
FutSwipe is a highly dynamic, visually stunning, fast-paced football trivia game. It replaces boring text-based quizzes with a "Tinder-style" swipe mechanic. Users are presented with a specific rule (e.g., "Played for FC Porto?") and a stack of visual cards (player faces, stadiums, jerseys). The goal is simple but intense: **How many correct swipes can you make in exactly 10 seconds?**

The UI must **not** feel static. It must look and feel like a top-tier Dribbble design: utilizing glassmorphism, neo-brutalism accents, 60/120 FPS animations, particle effects, and precise haptic feedback.

## 2. Core Gameplay Logic & Mechanics
*   **The Rule:** At the start of a round, a global rule is displayed at the top of the screen (e.g., "Won the Champions League").
*   **The Card:** A visual card appears in the center. It contains an image (e.g., Erling Haaland) and a name.
*   **The Action:**
    *   Swipe Right (or tap Green) if the card matches the rule.
    *   Swipe Left (or tap Red) if the card does NOT match the rule.
*   **The Validation (Blitz Mode):**
    *   *Correct:* +1 Score, Green glow, positive haptic feedback. Instant next card.
    *   *Incorrect:* Red screen shake, negative haptic feedback, 1-second penalty (or simply no points), but the game continues.
*   **The Timer:** The game is strictly timed. 
    *   **Global Timer:** Starts at **10.00 seconds**.
    *   **Game Over:** Happens exactly when the timer hits 0.00.

## 3. Dynamic Difficulty & Scoring System
*   **Scoring:** 1 Point per correct answer. 
*   **Speed Bonus:** If the user maintains a high swipe speed (e.g., > 2 swipes/sec), the background intensifies (red shift or particle storm).
*   **No Lives:** There are no lives. The only limit is time.
*   **Penalty:** An incorrect swipe freezes the input for 0.5s or deducts 1 second from the clock (Design choice: Deducting time is more punitive and exciting).

## 4. Screen-by-Screen UI/UX Specifications
**Global Theme:** Premium Dark Mode (`#0B131A` deep navy/black background). Elements use Glassmorphism (`BackdropFilter` with blur radius 10-15) over subtle animated mesh gradients.

### Screen 1: Gameplay Screen
*   **Top Bar:** Displays the current Rule (bold, white).
*   **The Timer:** A MASSIVE, semi-transparent countdown timer in the background or top center. As it drops below 3 seconds, it pulses huge and red.
*   **Center:** The Swipeable Card. Rounded corners (radius 24), subtle inner shadow. Contains high-res cached image.
*   **Bottom:** Minimalist action buttons (optional, as speed swiping is primary).

### Screen 2: Game Over Screen
*   **Center:** "TIME'S UP!" explosion animation.
*   **Score Reveal:** Your score (e.g., "14 Swipes") slams onto the screen.
*   **Comparison:** "Better than 80% of players" or "New Personal Best!".
*   **Action:** "Retry" button must be instant—one tap to restart immediately for "just one more try" addiction.

## 5. Data Model (Offline-First JSON/Dart Objects)
```dart
class QuizCard {
  final String id;
  final String title; // "Pepe"
  final String imageUrl;
  final Map<String, bool> rules; 
}
```

## 6. Required Flutter Tech Stack & Libraries
*   **State Management:** `flutter_riverpod` (Manage the countdown Stream and Score).
*   **Animations:** `flutter_animate` (Critical for the 10s countdown urgency effects).
*   **Swipe Mechanics:** `swipable_stack` or `appinio_swiper`.
*   **Haptics:** `flutter_vibrate` (Essential for "ticking" feeling in the last 3 seconds).

## 7. Advanced Design & UX Ideas (The "Wow" Factor)
To make this app stand out on Dribbble/App Store, implement these specific visual ideas:

1.  **"Heartbeat" Timer:** The entire screen border pulses red in sync with the last 5 seconds. The background mesh gradient rotates faster as time runs out.
2.  **Card Physics:** When swiping fast, the cards should "bend" or "warp" slightly based on velocity (Matrix-style distortion).
3.  **Combo Particles:**
    *   3 Correct in a row: Small sparks fly from the card.
    *   5 Correct in a row: Fire/Electric effect around the card borders.
    *   10 Correct in a row: The screen shakes slightly with every swipe (impact feedback).
4.  **Dynamic Soundscape:**
    *   Background ambient drone that pitches up as the timer decreases.
    *   Satisfying "Pop" or "Whoosh" sounds that vary in pitch (C, D, E, F, G...) as you get a streak effectively creating a melody.
5.  **Post-Game Heatmap:** Show a summary screen with a timeline of the 10 seconds, showing where the user was fast (green zone) and where they hesitated (red zone).

## 8. Instructions for the AI Agent
Based on this PRD, please provide the following:

1.  **Project Architecture:** Output the recommended directory structure.
2.  **Dependencies:** Provide the exact `pubspec.yaml` dependencies block.
3.  **Step 1 Code:** Generate the Riverpod State Notifier (`game_provider.dart`) that manages the **10-second countdown**, score, and card logic. Ensure the timer is precise (using `Ticker` or `Timer.periodic` with high precision).
