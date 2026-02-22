# Mixpanel Events (Hafiz Pro)

This document lists the Mixpanel events fired by the app, what they mean, and what triggers them.

## Quick notes (non-technical)

- Events are recorded in the production app. (They may not appear when running a developer/test build.)
- The current Web version does not send Mixpanel events.
- Many events include a time field called `timestamp`.

---

## 1) App + session events

### `App Launched`
- **Why**
  - Track cold start / app open.
- **Triggered when**
  - When the app is opened (app start).
- **Properties**
  - `timestamp`

### `App Lifecycle`
- **Why**
  - Track lifecycle state changes (foreground/background/etc.).
- **Triggered when**
  - When the app changes state (for example: opened, sent to background, hidden, or terminated).
- **Properties**
  - `lifecycle_state`
  - `timestamp`

### `Session Started`
- **Why**
  - Basic session tracking.
- **Triggered when**
  - When the app is opened.
  - When the app returns to the foreground after being in the background.
- **Properties**
  - `timestamp`

### `Session Ended`
- **Why**
  - Measure session length.
- **Triggered when**
  - When the app is sent to the background.
  - When the app is closed/terminated.
- **Properties**
  - `session_duration_seconds`
  - `timestamp`

---

## 2) Navigation / screen events

### `Screen View`
- **Why**
  - Track page/screen visits.
- **Triggered when**
  - When a user opens a screen in the app.
  - Examples:
    - Main Menu
    - Splash Screen
    - Settings
    - Surah List
    - Juz List
- **Properties**
  - `screen_name`
  - `timestamp`

### `Time Spent on Screen`
- **Why**
  - Measure time spent on the *previous* screen.
- **Triggered when**
  - When the user moves from one screen to another (the app logs how long the previous screen was open).
- **Properties**
  - `screen_name` (previous screen)
  - `time_spent_seconds`
  - `timestamp`

### `Back Pressed`
- **Why**
  - Understand navigation/back behavior (especially exits).
- **Triggered when**
  - When the user presses the device back button (or back navigation).
  - Includes the case where the user double-presses back to exit from the main menu.
- **Properties**
  - `from_screen`
  - `timestamp`

---

## 3) Content selection events

### `Surah Selected`
- **Why**
  - Track what users open/listen to.
- **Triggered when**
  - When the user selects a Surah (from any Surah list/card in the app).
- **Properties**
  - `surah_name`
  - `surah_number`
  - `timestamp`

### `Juz Selected`
- **Why**
  - Track what Juz users open/listen to.
- **Triggered when**
  - When the user selects a Juz (from any Juz list/card in the app).
- **Properties**
  - `juz_number`
  - `timestamp`

### `Last Read Continued`
- **Why**
  - Track use of “continue last session/last read” entry point.
- **Triggered when**
  - When the user taps “Continue” on the “Last Read” card.
- **Properties**
  - `surah_name`
  - `surah_number`
  - `ayah_number`
  - `timestamp`

---

## 4) Buttons / UI actions

### `Button Clicked`
- **Why**
  - Generic CTA/button tracking.
- **Triggered when**
  - When the user taps certain key buttons/CTAs.
  - Examples:
    - “Challenge Yourself”
    - “Settings” (opened from the Main Menu)
- **Properties**
  - `button_name`
  - `screen`
  - `timestamp`
  - (optional) `context` extra fields

---

## 5) Audio events

### `Audio Control`
- **Why**
  - Track play/pause/stop usage.
- **Triggered when**
  - When the user plays, pauses, or stops audio.
- **Properties**
  - `action` (`play` | `pause` | `stop`)
  - `audio_name`
  - `audio_type` (usually `recitation`)
  - `timestamp`

### `Audio Started`
- **Why**
  - Track when a recitation actually begins.
- **Triggered when**
  - When audio actually starts playing.
  - This can happen in:
    - Reading mode
    - Test mode
- **Properties**
  - `audio_name`
  - `audio_type` (default `recitation`)
  - `surah_name` (if provided)
  - `ayah_number` (if provided)
  - `is_playlist` (if provided)
  - `timestamp`

### `Audio Completed`
- **Why**
  - Track when a recitation finishes.
- **Triggered when**
  - When audio finishes playing.
  - This can happen in:
    - Reading mode
    - Test mode
- **Properties**
  - `audio_name`
  - `audio_type` (default `recitation`)
  - `surah_name` (if provided)
  - `ayah_number` (if provided)
  - `is_playlist` (sent as `wasPlaylist` in reading flow)
  - `timestamp`

### `Speed Changed`
- **Why**
  - Track playback speed usage.
- **Triggered when**
  - When the user changes playback speed.
- **Properties**
  - `new_speed`
  - `audio_name`
  - `timestamp`

### `Repeat Switch Toggled`
- **Why**
  - Track looping usage.
- **Triggered when**
  - When the user turns repeat/loop on or off.
- **Properties**
  - `repeat_enabled`
  - `audio_name`
  - `timestamp`

### `Audio Navigation`
- **Why**
  - Track moving between ayahs during test playback.
- **Triggered when**
  - When the user taps next/previous while listening during a test.
- **Properties**
  - `action` (`next` | `previous`)
  - `from_ayah`
  - `to_ayah`
  - `surah_name`

---

## 6) Test events

### `Test Refreshed`
- **Why**
  - Track generating a new random ayah (refresh in test).
- **Triggered when**
  - When the user taps refresh during a test to get a new ayah.
- **Properties**
  - `test_type` (e.g. `surah`)
  - `timestamp`
  - optional context (e.g. `surah_name`, `ayah_number`)

### `Test Started`
- **Why**
  - Track when a test begins.
- **Triggered when**
  - When a test begins.
- **Properties**
  - `test_type`
  - `timestamp`
  - `testDetails` (varies by caller)

### `Test Completed`
- **Why**
  - Track test completion and results.
- **Triggered when**
  - When a test finishes.
- **Properties**
  - `test_type`
  - `timestamp`
  - `testResults` (varies by caller)

---

## 7) Settings + external links

### `Settings Changed`
- **Why**
  - Track preference changes.
- **Triggered when**
  - When the user changes a setting (for example: autoplay or reciter).
- **Properties**
  - `setting_name`
  - `old_value`
  - `new_value`
  - `timestamp`

### `Website Link Clicked`
- **Why**
  - Track outbound link usage.
- **Triggered when**
  - When the user taps an external link from Settings (opens in the browser).
- **Properties**
  - `link_name`
  - `link_url`

### `Reciter WhatsApp Prompt Shown`
- **Why**
  - Track showing the “Want more reciters?” prompt.
- **Triggered when**
  - When the app shows the “Want more reciters?” prompt after changing reciter (only under certain conditions).
- **Properties**
  - `previous_reciter_id`
  - `selected_reciter_id`

### `Reciter WhatsApp Prompt Dismissed`
- **Why**
  - Track prompt dismissal.
- **Triggered when**
  - When the user taps “Not now” on the prompt.
- **Properties**
  - (none)

### `Reciter WhatsApp Prompt Join Clicked`
- **Why**
  - Track CTA click to join the WhatsApp group.
- **Triggered when**
  - When the user taps “Join group” on the prompt.
- **Properties**
  - (none)

### `Settings Rating Clicked`
- **Why**
  - Track opening the in-app rating flow from Settings.
- **Triggered when**
  - When the user taps “Rate us” in Settings.
- **Properties**
  - (none)

---

## 8) Rating feedback

### `Rating Feedback Submitted`
- **Why**
  - Capture user sentiment + optional comment.
- **Triggered when**
  - When the user submits the in-app rating dialog.
- **Properties**
  - `stars`
  - `comment`
  - `user_id` (from storage)
  - `platform` (`web` or OS)
