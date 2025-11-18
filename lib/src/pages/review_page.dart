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

  Map<String, Map<String, dynamic>> _profileCache = {};

  Stream<List<Map<String, dynamic>>> _ratingsStream() {
    return _client
        .from('product_ratings')
        .stream(primaryKey: ['id']).eq('product_id', widget.product.id);
  }

  Future<Map<String, dynamic>> _getProfile(String userId) async {
    if (_profileCache.containsKey(userId)) return _profileCache[userId]!;

    final res =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();

    final profile = res != null
        ? (res as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    _profileCache[userId] = profile;
    return profile;
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  Widget _initialAvatar(String name) {
    final initials = name.trim().isEmpty
        ? 'U'
        : name
            .trim()
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .take(2)
            .join()
            .toUpperCase();
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white10,
      child: Text(initials, style: const TextStyle(color: Colors.white)),
    );
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final userId = _client.auth.currentUser!.id;

      await _client.from('product_ratings').upsert({
        'user_id': userId,
        'product_id': widget.product.id,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,product_id');

      _commentController.clear();
      setState(() => _rating = 5);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barMaxWidth = screenWidth * 0.45;

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      backgroundColor: Colors.black87,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ratingsStream(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final rows = snap.data!
            ..sort((a, b) {
              final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                  DateTime.now();
              final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                  DateTime.now();
              return tb.compareTo(ta);
            });

          // Compute avg rating
          final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (var r in rows) {
            final rv = r['rating'] is int
                ? r['rating'] as int
                : int.tryParse(r['rating']?.toString() ?? '') ?? 0;
            if (rv >= 1 && rv <= 5) counts[rv] = counts[rv]! + 1;
          }
          final total = counts.values.fold<int>(0, (a, b) => a + b);
          double avg = total > 0
              ? counts.entries
                      .map((e) => e.key * e.value)
                      .reduce((a, b) => a + b) /
                  total
              : 0.0;

          Widget buildBar(int star) {
            final cnt = counts[star] ?? 0;
            final pct = total == 0 ? 0.0 : cnt / total;
            final width = (barMaxWidth * pct).clamp(4.0, barMaxWidth);
            return Row(
              children: [
                SizedBox(
                    width: 26,
                    child: Text('$star',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12))),
                const SizedBox(width: 6),
                Container(
                  width: barMaxWidth,
                  height: 10,
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                        width: pct == 0 ? 4 : width,
                        height: 10,
                        decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(6))),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                    width: 36,
                    child: Text('$cnt',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12))),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(avg.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                        Row(
                            children: List.generate(
                                5,
                                (i) => Icon(
                                    i < avg.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.greenAccent,
                                    size: 16))),
                        Text('$total reviews',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(children: [
                      buildBar(5),
                      buildBar(4),
                      buildBar(3),
                      buildBar(2),
                      buildBar(1)
                    ])),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Your review',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                Row(
                    children: List.generate(
                        5,
                        (i) => IconButton(
                            onPressed: () => setState(() => _rating = i + 1),
                            icon: Icon(
                                i < _rating ? Icons.star : Icons.star_border,
                                color: Colors.greenAccent)))),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Review'),
                ),
                const SizedBox(height: 24),
                FutureBuilder(
                  future: Future.wait(rows.map((r) async {
                    final profile = await _getProfile(r['user_id'].toString());
                    return {...r, 'profile': profile};
                  })),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final enriched =
                        snapshot.data as List<Map<String, dynamic>>;
                    return Column(
                      children: enriched.map((r) {
                        final profile = r['profile'] as Map<String, dynamic>;
                        final name = profile['full_name'] ??
                            profile['username'] ??
                            'User';
                        final avatarUrl = profile['avatar_url'] ?? '';
                        final comment = r['comment']?.toString() ?? '';
                        final created = DateTime.tryParse(
                                r['created_at']?.toString() ?? '') ??
                            DateTime.now();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              avatarUrl != ''
                                  ? ClipOval(
                                      child: Image.network(avatarUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _initialAvatar(name)))
                                  : _initialAvatar(name),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(name,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13))),
                                        Text(_timeAgo(created),
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12)),
                                      ],
                                    ),
                                    Row(
                                        children: List.generate(
                                            5,
                                            (i) => Icon(
                                                i < (r['rating'] ?? 0)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.greenAccent,
                                                size: 14))),
                                    Text(comment,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
