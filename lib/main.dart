import 'package:flutter/material.dart';
import 'package:nav_bars/screens/home_screen.dart';
import 'package:nav_bars/screens/login_screen.dart';
import 'package:nav_bars/screens/register_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nav_bars/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier(const Locale('pl'));
final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  final String initialRoute = '/login';
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
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
          },
        );
      },
    );
  }
}