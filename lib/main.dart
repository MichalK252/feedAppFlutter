import 'package:flutter/material.dart';
import 'package:nav_bars/screens/home_screen.dart';
import 'package:nav_bars/screens/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nav_bars/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier(const Locale('pl'));
final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ejtqfjbnbgwexjzjwjsx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqdHFmamJuYmd3ZXhqemp3anN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4MTAxODQsImV4cCI6MjA5MTM4NjE4NH0.8TfdqLAVzmNsvwQEXjuIer7sY8Uov8_vGyKrE5qYwlc', // wklej z Settings → API
  );
  final session = Supabase.instance.client.auth.currentSession;
  final String initialRoute = session != null ? '/home' : '/login';
  runApp(MainApp(initialRoute: initialRoute));
}

class MainApp extends StatelessWidget {
  final String initialRoute;

  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeNotifier,
          builder: (context, themeMode, child) {
            return MaterialApp(
              locale: locale,
              themeMode: themeMode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
                useMaterial3: true,
              ),
              title: 'Localizations Sample App',
              localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: initialRoute,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
          },
        );
      },
    );
  }
}