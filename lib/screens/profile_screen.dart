import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Brak emaila';
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Użytkownik';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit),
          label: const Text('Edytuj profil'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
