# App efficiency & memory backlog

Work items to reduce RAM usage, improve cold-start UX after OS kills, and keep performance solid on older devices (e.g. iPhone X). **Measure before large refactors** — use the profiling section first.

---

## Why this matters

- iOS may **terminate** background apps under memory pressure; low-RAM devices see this more often.
- A “fresh start” after ~1–2 minutes in background is often **process death**, not a Flutter resume bug.
- Efficiency lowers kill frequency; **persistence + restore** makes kills acceptable to users.

---

## 1. Measurement (do this first)

| Tool | Use for |
|------|---------|
| **Flutter DevTools → Memory** | Dart heap, growth over time, suspected leaks |
| **Xcode Instruments** (Allocations, Leaks, Memory Graph) | Native + total RSS on iOS |
| **Android Studio Profiler** | Same on Android |
| **Release builds on real devices** | Debug builds skew memory and performance |

**Record:** screen flow (e.g. open Quran → scroll → background → return), peak RSS, and whether the process actually restarted.

---

## 2. Lists & Quran read UI

- [ ] Audit `ScrollablePositionedList` / `itemBuilder`: avoid heavy work per item (sync parsing, large allocations).
- [ ] Prefer **one canonical** `Surah` / ayah list per screen; avoid duplicate full-text copies in multiple structures.
- [ ] Use **`const`** widgets where possible for static children (icons, decorations).
- [ ] Consider **`RepaintBoundary`** around expensive ayah rows if profiling shows repaint hotspots (helps CPU/GPU; indirect effect on smoothness).

---

## 3. Images & assets

- [ ] Ensure decorative assets (e.g. patterns) are **appropriately sized**; avoid oversized PNGs when a smaller asset or vector suffices.
- [ ] For any **`Image.network`**, set **`cacheWidth` / `cacheHeight`** (or equivalent) so decode size matches display size.
- [ ] Review **`Image.asset`** usage for large bitmaps; compress or downscale at source.

---

## 4. Audio (`just_audio` / `AudioCenter`)

- [ ] **Single player / single playlist owner** — avoid duplicate `AudioSource` graphs.
- [ ] **Release or clear** playlist when leaving listening-heavy flows if product allows (reduces native memory).
- [ ] Confirm subscriptions are **cancelled** in `dispose` everywhere audio is tied to a `State`.

---

## 5. Data layer (SQLite / services)

- [ ] Avoid loading **entire tables** into memory when UI only needs a **window**; use limits / pagination where applicable.
- [ ] Ensure **streams and listeners** are disposed; watch for unbounded caches in services.

---

## 6. Dart & isolates

- [ ] Move **CPU-heavy** work (bulk normalization, large search) off the UI isolate if it causes jank or large temporary allocations on the UI thread.
- [ ] Watch **large string** duplication for Quran text across models, notifiers, and maps.

---

## 7. Lifecycle & UX after OS kill

- [ ] **Persist** last meaningful context (surah, ayah, optional route) on **`paused`** or continuously — not only on `pop`.
- [ ] On **cold start**, optionally **deep-link** to last read Quran position (or home card) so restarts feel seamless.
- [ ] Document for QA: background + memory stress is **expected** to kill sometimes on small devices; success = **fast restore**, not “never killed.”

---

## 8. Build & CI habit

- [ ] Run periodic **profile/release** checks on a **low-end** physical device.
- [ ] Track a simple metric over time (e.g. peak MB after opening longest surah) if helpful.

---

## References in this repo (starting points)

- `lib/main.dart` — `WidgetsBindingObserver` / lifecycle (analytics only today).
- `lib/quran/quran_list.dart` — long list of ayahs.
- `lib/services/audio_center.dart` — central audio ownership.
- `lib/quran/quran_view.dart` — read screen composition.

---

## Notes

Add dated findings below as you profile (device, OS, peak memory, action → result).

```
<!-- Example:
## Findings
- 2025-03-26 — iPhone X, iOS 18: peak ~XXX MB after opening Al-Baqarah, scroll end-to-end.
-->
```
