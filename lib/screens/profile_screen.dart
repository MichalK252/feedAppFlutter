import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nav_bars/theme/app_theme.dart';
import 'package:nav_bars/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Brak emaila';
    final fullName =
        user?.userMetadata?['full_name'] as String? ?? 'Użytkownik';
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
            child: Text(
              'Profil',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar + info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu
          ListTile(
            leading: const Icon(Icons.edit_outlined, size: 22),
            title: const Text('Edytuj profil',
                style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right,
                size: 20, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
              // Refresh to show updated name
              if (mounted) setState(() {});
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline, size: 22),
            title: const Text('Polubione posty',
                style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right,
                size: 20, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const _LikedPostsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Liked Posts Screen ───────────────────────────────────────────
class _LikedPostsScreen extends StatefulWidget {
  const _LikedPostsScreen();

  @override
  State<_LikedPostsScreen> createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends State<_LikedPostsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _likedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikedPosts();
  }

  Future<void> _fetchLikedPosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get IDs of posts I liked
      final likesResponse = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final likedIds = List<Map<String, dynamic>>.from(likesResponse)
          .map((l) => l['post_id'])
          .toList();

      if (likedIds.isEmpty) {
        if (mounted) {
          setState(() {
            _likedPosts = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch the actual posts
      final postsResponse = await _supabase
          .from('posts')
          .select()
          .inFilter('id', likedIds)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _likedPosts = List<Map<String, dynamic>>.from(postsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'teraz';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) return '${diff.inHours} godz.';
      if (diff.inDays < 30) return '${diff.inDays} d.';
      return '${date.day}.${date.month}.${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Polubione posty')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedPosts.isEmpty
              ? const Center(
                  child: Text(
                    'Nie polubiłeś jeszcze żadnego posta',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchLikedPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _likedPosts.length,
                    itemBuilder: (context, index) {
                      final post = _likedPosts[index];
                      final author = post['author'] ?? 'Nieznany';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isDark
                              ? Border.all(color: AppTheme.darkBorder)
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      author.isNotEmpty
                                          ? author[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      author,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _timeAgo(post['created_at']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                post['content'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14, height: 1.4),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.favorite,
                                      size: 14, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Polubione',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
