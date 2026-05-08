
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nav_bars/theme/app_theme.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  List<String> _imageUrls = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final files = await _supabase.storage
          .from('photos')
          .list(path: userId);

      final urls = files
          .where((f) => !f.name.startsWith('.'))
          .map((f) => _supabase.storage
              .from('photos')
              .getPublicUrl('$userId/${f.name}'))
          .toList();

      if (mounted) {
        setState(() {
          _imageUrls = urls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd ładowania zdjęć: $e')),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Musisz być zalogowany')),
        );
      }
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploading = true);

      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final mimeType = _mimeType(ext);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = '${user.id}/$fileName';

      await _supabase.storage.from('photos').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      if (mounted) {
        setState(() => _isUploading = false);
        _fetchPhotos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zdjęcie dodane')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd przesyłania: $e')),
        );
      }
    }
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _deletePhoto(String url) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Extract file name from URL
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Path in storage is: photos/userId/filename
      // URL segments: ...storage/v1/object/public/photos/userId/filename
      final photosIndex = segments.indexOf('photos');
      if (photosIndex == -1 || photosIndex + 2 >= segments.length) return;
      final filePath =
          segments.sublist(photosIndex + 1).join('/');

      await _supabase.storage.from('photos').remove([filePath]);

      if (mounted) {
        _fetchPhotos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zdjęcie usunięte')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd usuwania: $e')),
        );
      }
    }
  }

  void _openPhoto(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoDetailScreen(
          url: url,
          onDelete: () {
            Navigator.of(context).pop();
            _deletePhoto(url);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _uploadPhoto,
        child: _isUploading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPhotos,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 56, 16, 4),
                      child: Text(
                        'Galeria',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '${_imageUrls.length} ${_imageUrls.length == 1 ? 'zdjęcie' : 'zdjęć'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  if (_imageUrls.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Brak zdjęć',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kliknij + żeby dodać pierwsze zdjęcie',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final url = _imageUrls[index];
                            return GestureDetector(
                              onTap: () => _openPhoto(url),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: isDark
                                        ? AppTheme.darkCard
                                        : Colors.grey.shade100,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: isDark
                                        ? AppTheme.darkCard
                                        : Colors.grey.shade100,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: _imageUrls.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }
}

// ── Full-screen photo view ──────────────────────────────────────
class _PhotoDetailScreen extends StatelessWidget {
  final String url;
  final VoidCallback onDelete;

  const _PhotoDetailScreen({
    required this.url,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Usunąć zdjęcie?'),
                  content: const Text('Tej operacji nie można cofnąć.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Anuluj'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      child: const Text('Usuń',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}
