import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce_sabi/src/models/product.dart';
import 'package:ecommerce_sabi/src/pages/review_page.dart';

class ProductRatingSection extends StatelessWidget {
  final Product product;
  const ProductRatingSection({super.key, required this.product});

  // Stream 10 review terbaru (realtime)
  Stream<List<Map<String, dynamic>>> _ratingsStream() {
    final client = Supabase.instance.client;
    // NOTE: if you want embedded profiles, consider using `.select('*, profiles(*)')`
    // with a normal query. Realtime stream often returns raw rows — fallback handled below.
    return client
        .from('product_ratings')
        .stream(primaryKey: ['id'])
        .eq('product_id', product.id)
        .order('created_at', ascending: false)
        .limit(10);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final barMaxWidth = screenWidth * 0.45;
    const accent = Color.fromRGBO(255, 202, 46, 1); // requested color

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ratingsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child:
                Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: Text('Failed to load ratings',
                    style: TextStyle(color: Colors.redAccent))),
          );
        }

        final rows = snap.data ?? [];

        // sort newest first (defensive)
        rows.sort((a, b) {
          final ta = a['created_at'] != null
              ? DateTime.tryParse(a['created_at'].toString()) ?? DateTime.now()
              : DateTime.now();
          final tb = b['created_at'] != null
              ? DateTime.tryParse(b['created_at'].toString()) ?? DateTime.now()
              : DateTime.now();
          return tb.compareTo(ta);
        });

        final recent = rows.take(3).toList();

        // compute counts (1..5)
        final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (var r in rows) {
          final v = r['rating'];
          int rv = 0;
          if (v is int)
            rv = v;
          else if (v is String) rv = int.tryParse(v) ?? 0;
          if (rv >= 1 && rv <= 5) counts[rv] = counts[rv]! + 1;
        }
        final total = counts.values.fold<int>(0, (a, b) => a + b);
        final avg = total > 0
            ? counts.entries
                    .map((e) => e.key * e.value)
                    .reduce((a, b) => a + b) /
                total
            : 0.0;

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
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12))),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (with increased horizontal padding)
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
                            fontSize: 14)),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.chevron_right, color: Colors.white70),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ReviewPage(product: product))),
                  ),
                ],
              ),
            ),

            // Summary (with padding)
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
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < avg.round() ? Icons.star : Icons.star_border,
                            color: accent,
                            size: 16,
                          ),
                        ),
                      ),
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
                      buildBar(1),
                    ]),
                  ),
                ],
              ),
            ),

            // Recent 3 reviews (with padding)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No reviews yet',
                          style: TextStyle(color: Colors.white54)),
                    )
                  else
                    ...recent.map((r) {
                      final profile = (r['profiles'] is Map)
                          ? Map<String, dynamic>.from(r['profiles'])
                          : null;

                      // prefer display_name -> full_name -> username -> short id
                      final name = profile != null
                          ? (profile['display_name'] ??
                              profile['full_name'] ??
                              profile['username'] ??
                              '')
                          : '';

                      final displayName =
                          (name != null && name.toString().trim().isNotEmpty)
                              ? name.toString()
                              : (r['user_id']?.toString().substring(0, 6) ??
                                  'User');

                      final avatarUrl =
                          profile != null ? (profile['avatar_url'] ?? '') : '';
                      final comment = (r['comment'] ?? '').toString();
                      final created = r['created_at'] != null
                          ? DateTime.tryParse(r['created_at'].toString()) ??
                              DateTime.now()
                          : DateTime.now();

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
                                            _initialAvatar(displayName)),
                                  )
                                : _initialAvatar(displayName),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Text(displayName,
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
                                  const SizedBox(height: 6),
                                  Row(
                                      children: List.generate(
                                          5,
                                          (i) => Icon(
                                              i < (r['rating'] ?? 0)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: accent,
                                              size: 14))),
                                  const SizedBox(height: 6),
                                  Text(comment,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
