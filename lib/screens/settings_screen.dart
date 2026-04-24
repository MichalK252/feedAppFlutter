import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nav_bars/l10n/app_localizations.dart';
import 'package:nav_bars/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final _url = Uri.parse('https://flutter.dev');

  String _getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return 'English';
      case 'es': return 'Espanol';
      case 'pl': return 'Polski';
      default: return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            l10n.accountHeading,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: Text(l10n.passwordAndSecurity),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _launchUrl(_url);
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: Text(l10n.notifications),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            l10n.appHeading,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: Text(l10n.darkMode),
          trailing: ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeNotifier,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) == Brightness.dark);
              return Switch(
                value: isDark,
                onChanged: (val) {
                  appThemeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.languageSetting),
          subtitle: ValueListenableBuilder<Locale>(
            valueListenable: appLocaleNotifier,
            builder: (context, locale, _) {
              return Text(_getLocaleName(locale));
            },
          ),
          trailing: DropdownButton<Locale>(
            value: appLocaleNotifier.value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down),
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                appLocaleNotifier.value = newLocale;
              }
            },
            items: AppLocalizations.supportedLocales.map((Locale locale) {
              return DropdownMenuItem(
                value: locale,
                child: Text(_getLocaleName(locale)),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: Text(
            l10n.logout,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ],
    );
  }
}

Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}
