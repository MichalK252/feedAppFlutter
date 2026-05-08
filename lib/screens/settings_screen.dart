import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nav_bars/l10n/app_localizations.dart';
import 'package:nav_bars/main.dart';
import 'package:nav_bars/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final _url = Uri.parse('https://flutter.dev');

  String _getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'pl':
        return 'Polski';
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
            child: Text(
              l10n.homeScreenTitle == 'Home' ? 'Settings' : 'Ustawienia',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),

          // ── Account ─────────────────────────────────────────────
          _SectionHeader(title: l10n.accountHeading),
          _SettingsGroup(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.security_outlined,
                title: l10n.passwordAndSecurity,
                onTap: () => _launchUrl(_url),
                showChevron: true,
              ),
              _Divider(isDark: isDark),
              _SettingsTile(
                icon: Icons.notifications_none,
                title: l10n.notifications,
                onTap: () {},
                showChevron: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── App ─────────────────────────────────────────────────
          _SectionHeader(title: l10n.appHeading),
          _SettingsGroup(
            isDark: isDark,
            children: [
              // Dark mode toggle
              ValueListenableBuilder<ThemeMode>(
                valueListenable: appThemeNotifier,
                builder: (context, themeMode, _) {
                  final isDarkMode = themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system &&
                          MediaQuery.platformBrightnessOf(context) ==
                              Brightness.dark);
                  return _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: l10n.darkMode,
                    trailing: Switch(
                      value: isDarkMode,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        appThemeNotifier.value =
                            val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                    onTap: () {
                      appThemeNotifier.value =
                          isDarkMode ? ThemeMode.light : ThemeMode.dark;
                    },
                  );
                },
              ),
              _Divider(isDark: isDark),
              // Language dropdown
              ValueListenableBuilder<Locale>(
                valueListenable: appLocaleNotifier,
                builder: (context, locale, _) {
                  return _SettingsTile(
                    icon: Icons.language,
                    title: l10n.languageSetting,
                    trailing: DropdownButton<Locale>(
                      value: locale,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      alignment: Alignment.centerRight,
                      onChanged: (Locale? newLocale) {
                        if (newLocale != null) {
                          appLocaleNotifier.value = newLocale;
                        }
                      },
                      items: AppLocalizations.supportedLocales.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Text(_getLocaleName(loc),
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Logout ──────────────────────────────────────────────
          _SettingsGroup(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.logout,
                title: l10n.logout,
                iconColor: AppTheme.danger,
                textColor: AppTheme.danger,
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Components ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsGroup({
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.showChevron = false,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? Colors.grey.shade600),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              // ignore: use_null_aware_elements
              if (trailing != null) trailing!,
              if (showChevron && trailing == null)
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 54, // Aligns with the text
      color: isDark ? AppTheme.darkBorder : Colors.grey.shade100,
    );
  }
}

Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}
