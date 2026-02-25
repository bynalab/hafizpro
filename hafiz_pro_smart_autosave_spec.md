# Smart Auto-Save Reading Progress System

## Hafiz Pro -- Implementation Specification

We are building a Qur'an reading app (Hafiz Pro) in Flutter.

We need to implement a **smart, silent auto-save reading progress
system** that detects meaningful reading behavior without using popups.

The system must work correctly for both long and very short surahs.

------------------------------------------------------------------------

## 🎯 Core Goal

Automatically mark verses as read when meaningful reading behavior is
detected.

There must be: - ❌ No popup dialogs - ❌ No confirmation prompts - ✅
Silent auto-save - ✅ Subtle bottom toast only if meaningful progress
was saved

Toast text:

    Progress updated ✔

Auto-dismiss after 2 seconds.

------------------------------------------------------------------------

## 🧠 Reading Detection Rules

A verse is confirmed as read ONLY if ALL conditions are met:

1.  The verse widget is fully visible on screen.
2.  It remains fully visible continuously for at least 4 seconds.
3.  The user is scrolling forward (not backward).
4.  The verse index is greater than the last saved verse index.

If visibility drops before 4 seconds, reset the timer.

------------------------------------------------------------------------

## 📊 Adaptive Save Logic (IMPORTANT)

Remove fixed time-based rules (e.g., 45 seconds).

Instead use percentage-based logic.

When the user exits the Surah screen (pop / back navigation / dispose):

1.  Calculate:

    -   `totalVersesInSurah`
    -   `confirmedReadVersesCount`
    -   `readingPercentage = confirmedReadVersesCount / totalVersesInSurah`

2.  Save progress ONLY IF:

    ✅ `readingPercentage >= 0.6` (60%)

    OR

    ✅ `confirmedReadVersesCount >= 3` (for long surahs where user made
    meaningful progress)

This ensures: - Short surahs (e.g., 3--5 verses) save correctly. - Long
surahs save after meaningful partial progress. - No artificial time
thresholds.

------------------------------------------------------------------------

## 🧩 State Tracking Requirements

Maintain the following:

-   `Set<int> confirmedReadVerses`
-   `Map<int, DateTime> verseVisibilityStartTime`
-   `int lastSavedVerseIndex`
-   `int totalVersesInSurah`

Use: - `ScrollController` - `visibility_detector` package

------------------------------------------------------------------------

## 🔄 On Surah Exit

When user leaves the screen:

1.  Evaluate save conditions.
2.  If conditions met:
    -   Persist updated Set`<int>`{=html} of read verses.
    -   Update lastSavedVerseIndex.
    -   Show bottom toast.
3.  If conditions NOT met:
    -   Do nothing.
    -   Show no toast.

------------------------------------------------------------------------

## ⚙️ Architecture Requirements

-   Implement logic inside a separate `ReadingProgressController` class.
-   UI must not contain business logic.
-   Avoid unnecessary rebuilds.
-   Avoid performance impact during scroll.
-   Ensure visibility detection does not trigger excessive state
    updates.

------------------------------------------------------------------------

## 🧘 UX Philosophy

The system must feel: - Intelligent - Calm - Invisible - Non-intrusive

Reading flow must never be interrupted.

No modal dialogs under any circumstance.

------------------------------------------------------------------------

## 💎 Future Extensibility

Design the controller so that later we can add:

"Reading Progress Mode" - Smart Auto (default) - Manual - Ask Every Time

But implement Smart Auto only for now.

------------------------------------------------------------------------

End of specification.
