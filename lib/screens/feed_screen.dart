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

  Future<void> _addPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;
    
    final user = _supabase.auth.currentUser;
    final author = user?.email?.split('@')[0] ?? 'Anonim';

    try {
      await _supabase.from('posts').insert({
        'author': author,
        'content': content,
      });
      if (mounted) {
        _postController.clear();
        Navigator.of(context).pop();
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('posts')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd pobierania postów: ${snapshot.error}'));
          }
          
          final posts = snapshot.data ?? [];
          
          if (posts.isEmpty) {
            return const Center(child: Text('Brak postów. Bądź pierwszy!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
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
                          Text(
                            post['author'] ?? 'Nieznany',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
          );
        },
      ),
    );
  }
}
