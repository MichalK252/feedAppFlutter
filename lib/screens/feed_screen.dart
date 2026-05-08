import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nav_bars/theme/app_theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postController = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  Map<dynamic, int> _likeCounts = {};
  Set<dynamic> _myLikes = {};
  bool _isLoading = true;

  String get _myUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final posts = List<Map<String, dynamic>>.from(response);

      // Fetch all likes
      final postIds = posts.map((p) => p['id']).toList();
      Map<dynamic, int> counts = {};
      Set<dynamic> myLikes = {};

      if (postIds.isNotEmpty) {
        final likesResponse = await _supabase
            .from('post_likes')
            .select()
            .inFilter('post_id', postIds);

        final likes = List<Map<String, dynamic>>.from(likesResponse);
        for (final like in likes) {
          final pId = like['post_id'];
          counts[pId] = (counts[pId] ?? 0) + 1;
          if (like['user_id'] == _myUserId) {
            myLikes.add(pId);
          }
        }
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _likeCounts = counts;
          _myLikes = myLikes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd pobierania postów: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike(dynamic postId) async {
    if (_myUserId.isEmpty) return;

    final liked = _myLikes.contains(postId);

    // Optimistic update
    setState(() {
      if (liked) {
        _myLikes.remove(postId);
        _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
      } else {
        _myLikes.add(postId);
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
      }
    });

    try {
      if (liked) {
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', _myUserId);
      } else {
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': _myUserId,
        });
      }
    } catch (e) {
      // Revert on error
      _fetchPosts();
    }
  }

  Future<void> _deletePost(dynamic id) async {
    try {
      await _supabase.from('posts').delete().eq('id', id);
      _fetchPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd usuwania posta: $e')),
        );
      }
    }
  }

  Future<void> _addPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Musisz być zalogowany')),
        );
      }
      return;
    }

    final author = user.email?.split('@')[0] ?? 'Anonim';

    try {
      await _supabase.from('posts').insert({
        'user_id': user.id,
        'author': author,
        'content': content,
      });
      if (mounted) {
        _postController.clear();
        Navigator.of(context).pop();
        _fetchPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd dodawania posta: $e')),
        );
      }
    }
  }

  void _showAddPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nowy post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _postController,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Co słychać?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _postController.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Anuluj'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _addPost,
                      child: const Text('Publikuj'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostSheet,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPosts,
              child: _posts.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'Brak postów.\nBądź pierwszy!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 90),
                      itemCount: _posts.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
                            child: Text(
                              'Feed',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          );
                        }
                        final post = _posts[index - 1];
                        final postId = post['id'];
                        final user = _supabase.auth.currentUser;
                        final isMyPost =
                            user != null && post['user_id'] == user.id;
                        final author = post['author'] ?? 'Nieznany';
                        final timeAgo = _timeAgo(post['created_at']);
                        final likeCount = _likeCounts[postId] ?? 0;
                        final iLiked = _myLikes.contains(postId);

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
                                      radius: 18,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        author.isNotEmpty
                                            ? author[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            author,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (timeAgo.isNotEmpty)
                                            Text(
                                              timeAgo,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isMyPost)
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            size: 20,
                                            color: Colors.grey.shade400),
                                        onPressed: () =>
                                            _deletePost(post['id']),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  post['content'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.4),
                                ),
                                const SizedBox(height: 10),
                                // Like row
                                GestureDetector(
                                  onTap: () => _toggleLike(postId),
                                  child: Row(
                                    children: [
                                      Icon(
                                        iLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 20,
                                        color: iLiked
                                            ? Colors.red
                                            : Colors.grey.shade400,
                                      ),
                                      if (likeCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: iLiked
                                                ? Colors.red
                                                : Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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
