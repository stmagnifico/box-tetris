# Box Tetris

Cross-platform Flutter app for optimizing box storage using **matryoshka nesting** — placing smaller boxes inside larger ones to minimize total shelf footprint.

## Architecture

- **Clean Architecture** layers under `lib/features/boxes/`:
  - `domain/` — `Box`, `NestingNode`, `NestingResult`, `BoxOptimizer`
  - `presentation/` — Riverpod state + Material UI
- **`lib/features/cv/`** — stub for future camera/CV dimension input

## Getting started

```bash
# From an empty platform folder, generate ios/android/web once:
flutter create . --project-name box_tetris

flutter pub get
flutter devices          # find your phone ID
flutter run -d <device>  # debug on phone → hot reload with r, or save in IDE
flutter test
```

### Hot reload on a physical phone

1. Enable **USB debugging** on the phone and connect via cable (or set up [wireless debugging](https://developer.android.com/tools/adb#wireless-android11)).
2. Run `flutter devices` — the phone should appear in the list.
3. Start debug mode:
   - **Terminal:** `flutter run -d <device_id>` then press `r` (hot reload) or `R` (full restart).
   - **Cursor / VS Code:** Run **BoxTetris (debug)** from the Run panel (`.vscode/launch.json`). With `dart.flutterHotReloadOnSave` enabled, saving a `.dart` file reloads on the phone automatically.

> Changes to `config/seed_boxes.json` require **hot restart** (`R`) or a new `flutter run` — assets are not hot-reloaded.

## Core algorithm

`BoxOptimizer`:

1. Builds valid parent assignments (forest, no cycles): box A nested in B only if A’s outer dimensions (any 90° rotation) are **strictly less** than B’s inner cavity.
2. Minimizes the sum of **root** outer volumes (nested boxes do not add to footprint).
3. Uses exhaustive search for ≤12 boxes; greedy heuristic for larger lists.

## UI flow

1. **Home** — list boxes, add W×H×D manually, optional wall thickness and label.
2. **Calculate optimization** — runs `BoxOptimizer`, opens results.
3. **Results** — volume stats (before / after / saved %) + `ExpansionTile` nesting tree.

## Units

Dimensions are entered in **centimeters**; volumes display as cm³, liters, or m³ depending on magnitude.

## Seed data (dev / manual testing)

Edit `config/seed_boxes.json` before running the app:

```json
{
  "enabled": true,
  "boxes": [
    { "label": "Container", "width": 20, "height": 20, "depth": 20, "wallThickness": 0 },
    { "label": "Flat A", "width": 19, "height": 19, "depth": 9 }
  ]
}
```

- Set `"enabled": false` to start with an empty list.
- After changing the file, restart the app (hot reload does not reload assets).
- Fields: `width`, `height`, `depth` (required), `wallThickness` and `label` (optional).
