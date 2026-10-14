import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens.dart';
import 'state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.init();
  runApp(const StudyTrackApp());
}

class StudyTrackApp extends StatelessWidget {
  const StudyTrackApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (c, _) {
          final d = app.dark;
          final scheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5), brightness: d ? Brightness.dark : Brightness.light,
            primary: const Color(0xFF4F46E5), onPrimary: Colors.white, secondary: const Color(0xFF14B8A6), tertiary: const Color(0xFFF59E0B),
            surface: d ? const Color(0xFF1E293B) : Colors.white, onSurface: d ? const Color(0xFFE2E8F0) : const Color(0xFF172033),
          );
          final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: d ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'StudyTrack',
            locale: Locale(app.lang),
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
            theme: base.copyWith(textTheme: GoogleFonts.vazirmatnTextTheme(base.textTheme), appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0)),
            home: const Shell(),
          );
        },
      );
}
