import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce_sabi/src/models/product.dart';
import 'package:ecommerce_sabi/src/pages/user/review_page.dart';

class ProductRatingPreview extends StatefulWidget {
  final Product product;

  /// optional: use your appbar asset path if needed for consistency
  final String? appBarAsset;
  const ProductRatingPreview(
      {super.key, required this.product, this.appBarAsset});

  @override
  State<ProductRatingPreview> createState() => _ProductRatingPreviewState();
}

class _ProductRatingPreviewState extends State<ProductRatingPreview> {
  final SupabaseClient _client = Supabase.instance.client;
  StreamController<List<Map<String, dynamic>>>? _controller;
  Timer? _pollTimer;
  static const int _pollSeconds = 4; // adjustable

  @override
  void initState() {
    super.initState();
    _ensureController();
  }

  void _ensureController() {
    if (_controller != null && !_controller!.isClosed) return;
    _controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () => _startPolling(),
      onCancel: () => _stopPolling(),
    );
  }

  void _startPolling() {
    _loadReviewsAndAdd();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: _pollSeconds), (_) {
      _loadReviewsAndAdd();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _loadReviewsAndAdd() async {
    try {
      final res = await _client
          .from('product_ratings')
          .select(
              'id, rating, comment, created_at, user_id, users(display_name,username,avatar_url)')
          .eq('product_id', widget.product.id)
          .order('created_at', ascending: false)
          .limit(10); // fetch some rows to compute avg/count, we'll show top 3

      final rows = <Map<String, dynamic>>[];
      for (final item in res) {
        rows.add(Map<String, dynamic>.from(item));
      }

      if (_controller != null && !_controller!.isClosed) _controller!.add(rows);
    } catch (e, st) {
      debugPrint('ProductRatingPreview loadReviews error: $e\n$st');
      _controller?.addError(e);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller?.close();
    super.dispose();
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
        child: Text(initials, style: const TextStyle(color: Colors.white)));
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

  @override
  Widget build(BuildContext context) {
    const accent = Color.fromRGBO(255, 202, 46, 1);
    final screenWidth = MediaQuery.of(context).size.width;
    final barMaxWidth = screenWidth * 0.45;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller?.stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Failed to load ratings',
                style: TextStyle(color: Colors.redAccent)),
          );
        }

        final rows = snap.data ?? <Map<String, dynamic>>[];

        // compute counts & avg
        final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (var r in rows) {
          final v = r['rating'];
          int rv = 0;
          if (v is int) {
            rv = v;
          } else if (v is String) {
            rv = int.tryParse(v) ?? 0;
          }
          if (rv >= 1 && rv <= 5) {
            counts[rv] = counts[rv]! + 1;
          }
        }
        final total = counts.values.fold<int>(0, (a, b) => a + b);
        final avg = total > 0
            ? counts.entries
                    .map((e) => e.key * e.value)
                    .reduce((a, b) => a + b) /
                total
            : 0.0;

        final recent = rows.take(3); // show 3 latest only

        Widget buildBar(int star) {
          final cnt = counts[star] ?? 0;
          final pct = total == 0 ? 0.0 : cnt / total;
          final width = (barMaxWidth * pct).clamp(4.0, barMaxWidth);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                    width: 26,
                    child: Text('$star',
                        style: const TextStyle(color: Colors.white70))),
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
                        width: pct == 0 ? 4.0 : width,
                        height: 10,
                        decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(6))),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                    width: 36,
                    child: Text('$cnt',
                        style: const TextStyle(color: Colors.white70))),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                      child: Text('Ratings and Reviews',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14))),
                  IconButton(
                    icon:
                        const Icon(Icons.chevron_right, color: Colors.white70),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewPage(
                            product: widget
                                .product, // wajib, karena ReviewPage butuh Product
                            appBarAsset: widget.appBarAsset, // opsional
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),

            // summary
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(avg.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                              5,
                              (i) => Icon(
                                  i < avg.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: accent,
                                  size: 16))),
                      const SizedBox(height: 4),
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
            ),

            // latest 3 reviews preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recent.isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No reviews yet',
                            style: TextStyle(color: Colors.white54)))
                  else
                    ...recent.map((r) {
                      final profile = (r['users'] is Map)
                          ? Map<String, dynamic>.from(r['users'] as Map)
                          : null;
                      final name = profile != null
                          ? (profile['display_name'] ??
                              profile['username'] ??
                              'User')
                          : (r['user_id']?.toString().substring(0, 6) ??
                              'User');
                      final avatarUrl =
                          profile != null ? (profile['avatar_url'] ?? '') : '';
                      final comment = (r['comment'] ?? '').toString();
                      final created = r['created_at'] != null
                          ? DateTime.tryParse(r['created_at'].toString()) ??
                              DateTime.now()
                          : DateTime.now();
                      final rating = r['rating'] is int
                          ? r['rating'] as int
                          : int.tryParse((r['rating'] ?? '').toString()) ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                                    Row(children: [
                                      Expanded(
                                          child: Text(name,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Text(_timeAgo(created),
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12)),
                                    ]),
                                    const SizedBox(height: 6),
                                    Row(
                                        children: List.generate(
                                            5,
                                            (i) => Icon(
                                                i < rating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: accent,
                                                size: 14))),
                                    const SizedBox(height: 6),
                                    Text(comment,
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                  ]),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 14),
          ],
        );
      },
    );
  }
}
