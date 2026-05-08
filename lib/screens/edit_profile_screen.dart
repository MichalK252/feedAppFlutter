import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nav_bars/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _supabase = Supabase.instance.client;

  // Name
  late final TextEditingController _nameController;

  // Password
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _isSavingName = false;
  bool _isSavingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? '';
    _nameController = TextEditingController(text: fullName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Save display name ──────────────────────────────────────────
  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnack('Podaj imię');
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );
      if (mounted) {
        _showSnack('Imię zostało zaktualizowane', isError: false);
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack('Błąd: $e');
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  // ── Change password ────────────────────────────────────────────
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isSavingPassword = true);
    try {
      // First, re-authenticate with current password to verify identity
      final email = _supabase.auth.currentUser?.email;
      if (email == null) {
        _showSnack('Brak emaila użytkownika');
        return;
      }

      await _supabase.auth.signInWithPassword(
        email: email,
        password: _currentPasswordController.text,
      );

      // Now update to the new password
      await _supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSnack('Hasło zostało zmienione', isError: false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (e.message.toLowerCase().contains('invalid') ||
            e.message.toLowerCase().contains('credentials')) {
          _showSnack('Obecne hasło jest nieprawidłowe');
        } else {
          _showSnack(e.message);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Błąd: $e');
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = _supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Edytuj profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── Email (read-only) ────────────────────────────────
          _SectionLabel(text: 'EMAIL'),
          const SizedBox(height: 6),
          _Card(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.mail_outline,
                      size: 20, color: Colors.grey.shade500),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Nie można zmienić',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Display name ────────────────────────────────────
          _SectionLabel(text: 'WYŚWIETLANA NAZWA'),
          const SizedBox(height: 6),
          _Card(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StyledTextField(
                    controller: _nameController,
                    label: 'Imię i nazwisko',
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _PrimaryButton(
                    label: 'Zapisz nazwę',
                    isLoading: _isSavingName,
                    onPressed: _saveName,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Change password ─────────────────────────────────
          _SectionLabel(text: 'ZMIANA HASŁA'),
          const SizedBox(height: 6),
          _Card(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StyledTextField(
                      controller: _currentPasswordController,
                      label: 'Obecne hasło',
                      icon: Icons.lock_outline,
                      isDark: isDark,
                      obscureText: _obscureCurrent,
                      toggleObscure: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Podaj obecne hasło' : null,
                    ),
                    const SizedBox(height: 12),
                    _StyledTextField(
                      controller: _newPasswordController,
                      label: 'Nowe hasło',
                      icon: Icons.lock_reset_outlined,
                      isDark: isDark,
                      obscureText: _obscureNew,
                      toggleObscure: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Podaj nowe hasło';
                        if (v.length < 6) {
                          return 'Hasło musi mieć min. 6 znaków';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _StyledTextField(
                      controller: _confirmPasswordController,
                      label: 'Powtórz nowe hasło',
                      icon: Icons.lock_outline,
                      isDark: isDark,
                      obscureText: _obscureConfirm,
                      toggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Powtórz hasło';
                        if (v != _newPasswordController.text) {
                          return 'Hasła się nie zgadzają';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      label: 'Zmień hasło',
                      isLoading: _isSavingPassword,
                      onPressed: _changePassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
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

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
      ),
      child: child,
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final VoidCallback? toggleObscure;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.toggleObscure,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        prefixIcon:
            Icon(icon, size: 20, color: Colors.grey.shade500),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
