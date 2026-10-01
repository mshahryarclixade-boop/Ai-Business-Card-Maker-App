# AI Business Card Maker

## Structure
```
lib/
  app/
    core/
      theme/
        app_colors.dart       # all colors live here
        app_text_styles.dart  # all text styles live here
    modules/
      splash/
        controller/
        view/
        service/
      onboarding/   <- add same 3 folders when we build it
      home/         <- same pattern
    routes/
      app_routes.dart
      app_pages.dart
  main.dart
```
Every new screen = new folder under `modules/` with its own
`controller/`, `view/`, `service/` — same as `splash`.

## Fonts
The Figma spec uses SF Pro (Apple system font, not redistributable).
Two options:
1. Leave as-is — iOS will render it close to native since SF is the
   default iOS font; Android will fall back to Roboto.
2. Drop licensed SF Pro `.ttf` files into `assets/fonts/`, then
   uncomment the `fonts:` section in `pubspec.yaml`.

## Run
```
flutter pub get
flutter run
```

## Status
✅ Splash screen (animated progress bar, single-file, no GetX controller)
✅ Onboarding (3 swipeable screens, GetX controller for PageView state only)
✅ Home screen (generate-with-AI card, feature grid, custom create, recent designs, bottom nav)
⬜ Template / Contacts / Profile screens
⬜ Backend / API integration — intentionally skipped for now, UI-first per plan.

## Images needed
Drop these into `assets/images/` (see assets/images/README.txt):
- onboarding1.png
- onboarding2.png
- onboarding3.png

Home screen currently uses Material icons as placeholders for the custom
Figma icons (AI sparkle, scan frame, QR, etc). Swap in real assets under
`assets/images/` and reference them in `feature_grid.dart` when ready.
