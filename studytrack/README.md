# StudyTrack (Flutter)

## Setup
1. Install Flutter (stable, Dart >= 3.3) and run `flutter doctor`.
2. In an empty folder: `flutter create --org com.example --project-name studytrack .`
3. Replace the generated `pubspec.yaml` and `lib/` with the ones from this project.
4. `flutter pub get && flutter run` (Android minSdk 21+ is fine; iOS works unchanged).
Note: the Vazirmatn font is fetched by google_fonts on first launch (internet needed once);
to ship offline, add the font files under assets/ and replace GoogleFonts in main.dart.

## Structure
lib/db.dart (SQLite models + CRUD + demo data) · lib/state.dart (state, timer, statistics)
lib/i18n.dart (fa/en strings, RTL, Jalali, digits) · lib/screens.dart (UI) · lib/main.dart (theme, locale)
