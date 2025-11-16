import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ReviewPage extends StatefulWidget {
  final Product product;
  const ReviewPage({super.key, required this.product});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  Stream<List<Map<String, dynamic>>> _ratingsStream() {
    return _client
        .from('product_ratings')
        .stream(primaryKey: ['id']).eq('product_id', widget.product.id);
  }

  Future<void> _submitReview() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _client.from('product_ratings').upsert(
        {
          'user_id': userId,
          'product_id': widget.product.id,
          'rating': _rating,
          'comment': _commentController.text,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,product_id', // gabung jadi satu string
      );

      if (response.error != null) {
        throw response.error!;
      }

      _commentController.clear();
      setState(() => _rating = 5);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStars() {
    return Row(
      children: List.generate(
        5,
        (i) => IconButton(
          icon: Icon(
            i < _rating ? Icons.star : Icons.star_border,
            color: Colors.orangeAccent,
          ),
          onPressed: () => setState(() => _rating = i + 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for ${widget.product.name}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Review:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                _buildStars(),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Write your comment...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('Submit Review'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ratingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const Center(child: Text('No reviews yet'));
                }

                // sort by latest
                reviews.sort((a, b) {
                  final ta = DateTime.tryParse(a['created_at'] ?? '') ??
                      DateTime.now();
                  final tb = DateTime.tryParse(b['created_at'] ?? '') ??
                      DateTime.now();
                  return tb.compareTo(ta);
                });

                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final r = reviews[index];
                    final comment = r['comment'] ?? '';
                    final rating = r['rating'] ?? 0;
                    final createdAt =
                        DateTime.tryParse(r['created_at'] ?? '') ??
                            DateTime.now();
                    final userName =
                        (r['profiles']?['full_name'] ?? 'User').toString();

                    return ListTile(
                      title: Text(userName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.orangeAccent,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(comment),
                          const SizedBox(height: 2),
                          Text(
                            createdAt.toLocal().toString(),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
