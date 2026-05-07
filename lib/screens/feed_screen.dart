import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postController = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

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
          
      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(response);
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

  void _showAddPostDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Napisz nowy post'),
          content: TextField(
            controller: _postController,
            decoration: const InputDecoration(
              hintText: 'Co masz na myśli?',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _postController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: _addPost,
              child: const Text('Publikuj'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        tooltip: 'Dodaj post',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('Brak postów. Bądź pierwszy!'))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _posts.length,
                   itemBuilder: (context, index) {
                     final post = _posts[index];
              final user = _supabase.auth.currentUser;
              final isMyPost = user != null && post['user_id'] == user.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              post['author'] ?? 'Nieznany',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isMyPost)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePost(post['id']),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post['content'] ?? '',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
