import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ReviewPage extends StatefulWidget {
  final Product product;
  final String? appBarAsset;

  const ReviewPage({super.key, required this.product, this.appBarAsset});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final SupabaseClient _client = Supabase.instance.client;

  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  bool _isLoggedIn = false;
  bool _hasPurchased = false;
  bool _hasReviewed = false;
  bool _checkingEligibility = true;

  StreamController<List<Map<String, dynamic>>>? _controller;
  Timer? _pollTimer;
  static const int _pollSeconds = 4;

  @override
  void initState() {
    super.initState();
    _ensureController();
    _initAuthAndEligibility();
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
              'id, rating, comment, created_at, user_id, profiles(display_name,username,avatar_url)')
          .eq('product_id', widget.product.id)
          .order('created_at', ascending: false)
          .limit(200);

      final rows = <Map<String, dynamic>>[];
      if (res is List) {
        for (var e in res) {
          if (e is Map) rows.add(Map<String, dynamic>.from(e));
        }
      }

      if (_controller != null && !_controller!.isClosed) _controller!.add(rows);
    } catch (e, st) {
      debugPrint('loadReviews error: $e\n$st');
      _controller?.addError(e);
    }
  }

  Future<void> _initAuthAndEligibility() async {
    setState(() => _checkingEligibility = true);

    final session = _client.auth.currentSession;
    final loggedIn = session != null;
    setState(() => _isLoggedIn = loggedIn);

    if (!loggedIn) {
      await _loadReviewsAndAdd();
      setState(() {
        _hasPurchased = false;
        _hasReviewed = false;
        _checkingEligibility = false;
      });
      return;
    }

    final userId = session!.user.id;

    try {
      final reviewRes = await _client
          .from('product_ratings')
          .select('id')
          .eq('product_id', widget.product.id)
          .eq('user_id', userId)
          .maybeSingle();
      final hasReviewed = reviewRes != null;

      final ordersResp =
          await _client.from('orders').select('id').eq('user_id', userId);

      bool hasPurchased = false;
      if (ordersResp is List && ordersResp.isNotEmpty) {
        final orderIds = <String>[];
        for (var o in ordersResp) {
          if (o is Map && o['id'] != null) orderIds.add(o['id'].toString());
        }

        if (orderIds.isNotEmpty) {
          final oiResp = await _client
              .from('order_items')
              .select('order_id, product_id')
              .eq('product_id', widget.product.id);

          if (oiResp is List) {
            for (var it in oiResp) {
              if (it is Map && it['order_id'] != null) {
                final oid = it['order_id'].toString();
                if (orderIds.contains(oid)) {
                  hasPurchased = true;
                  break;
                }
              }
            }
          }
        }
      }

      setState(() {
        _hasReviewed = hasReviewed;
        _hasPurchased = hasPurchased;
      });
    } catch (e) {
      debugPrint('eligibility check error: $e');
      setState(() {
        _hasReviewed = false;
        _hasPurchased = false;
      });
    } finally {
      await _loadReviewsAndAdd();
      setState(() => _checkingEligibility = false);
    }
  }

  Future<void> _submitReview() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to submit review')));
      return;
    }
    if (!_hasPurchased) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You must buy this product before reviewing')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = session.user.id;
      await _client.from('product_ratings').upsert({
        'user_id': userId,
        'product_id': widget.product.id,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,product_id');

      await _initAuthAndEligibility();
      await _loadReviewsAndAdd();

      _commentController.clear();
      setState(() => _rating = 5);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Review submitted')));
    } catch (e) {
      debugPrint('submit error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
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

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller?.close();
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildNotLoggedInNotice() {
    return Column();
  }

  Widget _buildNotPurchasedNotice() {
    return Column();
  }

  Widget _buildAlreadyReviewedNotice() {
    return Column();
  }

  Widget _buildSubmitArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _commentController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Write your review',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          minLines: 1,
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        Row(
            children: List.generate(5, (i) {
          return IconButton(
            icon: Icon(i < _rating ? Icons.star : Icons.star_border,
                color: Color.fromRGBO(255, 202, 46, 1)),
            onPressed: () => setState(() => _rating = i + 1),
          );
        })),
        const SizedBox(height: 8),
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
      ],
    );
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: widget.appBarAsset != null
            ? Image.asset(widget.appBarAsset!, height: 36, fit: BoxFit.contain)
            : const Text('Ratings & Reviews',
                style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === header summary: CENTER the left box and ensure alignment ===
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: constrained box so the avg rating block is centered inside it
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 100, minWidth: 80),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // average value will be computed from stream snapshot below;
                          // display placeholder while waiting
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _controller!.stream,
                            builder: (context, snap) {
                              final rows =
                                  snap.data ?? <Map<String, dynamic>>[];
                              final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
                              for (var r in rows) {
                                final rv = r['rating'] is int
                                    ? r['rating'] as int
                                    : int.tryParse(
                                            (r['rating'] ?? '').toString()) ??
                                        0;
                                if (rv >= 1 && rv <= 5)
                                  counts[rv] = counts[rv]! + 1;
                              }
                              final total =
                                  counts.values.fold<int>(0, (a, b) => a + b);
                              final avg = total > 0
                                  ? (counts.entries
                                          .map((e) => e.key * e.value)
                                          .reduce((a, b) => a + b) /
                                      total)
                                  : 0.0;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(avg.toStringAsFixed(1),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                          5,
                                          (i) => Icon(
                                              i < avg.round()
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Color.fromRGBO(
                                                  255, 202, 46, 1),
                                              size: 14))),
                                  const SizedBox(height: 6),
                                  Text('$total reviews',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // RIGHT: rating bars
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _controller!.stream,
                      builder: (context, snap) {
                        final rows = snap.data ?? <Map<String, dynamic>>[];
                        final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
                        for (var r in rows) {
                          final rv = r['rating'] is int
                              ? r['rating'] as int
                              : int.tryParse((r['rating'] ?? '').toString()) ??
                                  0;
                          if (rv >= 1 && rv <= 5) counts[rv] = counts[rv]! + 1;
                        }
                        final total =
                            counts.values.fold<int>(0, (a, b) => a + b);

                        Widget buildBar(int star) {
                          final cnt = counts[star] ?? 0;
                          final pct = total == 0 ? 0.0 : cnt / total;
                          final width =
                              (barMaxWidth * pct).clamp(4.0, barMaxWidth);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: 26,
                                    child: Text('$star',
                                        style: const TextStyle(
                                            color: Colors.white70))),
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
                                            color:
                                                Color.fromRGBO(255, 202, 46, 1),
                                            borderRadius:
                                                BorderRadius.circular(6))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                    width: 36,
                                    child: Text('$cnt',
                                        style: const TextStyle(
                                            color: Colors.white70))),
                              ],
                            ),
                          );
                        }

                        return Column(children: [
                          buildBar(5),
                          buildBar(4),
                          buildBar(3),
                          buildBar(2),
                          buildBar(1)
                        ]);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // SINGLE divider only
            const Divider(color: Colors.white12),

            // Submit area OR a compact notice. If submit area is not shown, we render a small SizedBox (no extra divider).
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
              child: _checkingEligibility
                  ? const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator()))
                  : (!_isLoggedIn
                      ? _buildNotLoggedInNotice()
                      : (!_hasPurchased
                          ? _buildNotPurchasedNotice()
                          : (_hasReviewed
                              ? _buildAlreadyReviewedNotice()
                              : _buildSubmitArea()))),
            ),

            // NO second divider here — prevents double line + empty gap

            // Reviews list (fills remaining space)
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _controller!.stream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                        child: Text('Error: ${snap.error}',
                            style: const TextStyle(color: Colors.redAccent)));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rows = snap.data!
                    ..sort((a, b) {
                      final ta = DateTime.tryParse(
                              a['created_at']?.toString() ?? '') ??
                          DateTime.now();
                      final tb = DateTime.tryParse(
                              b['created_at']?.toString() ?? '') ??
                          DateTime.now();
                      return tb.compareTo(ta);
                    });

                  if (rows.isEmpty) {
                    return const Center(
                        child: Text('No reviews yet',
                            style: TextStyle(color: Colors.white70)));
                  }

                  return RefreshIndicator(
                    onRefresh: _loadReviewsAndAdd,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12),
                      itemBuilder: (context, idx) {
                        final r = rows[idx];
                        final profileMap = (r['profiles'] is Map)
                            ? Map<String, dynamic>.from(r['profiles'] as Map)
                            : null;
                        final name = profileMap != null
                            ? (profileMap['username'] ??
                                profileMap['display_name'] ??
                                'User')
                            : (r['user_id']?.toString().substring(0, 6) ??
                                'User');
                        final avatarUrl = profileMap != null
                            ? (profileMap['avatar_url'] ?? '')
                            : '';
                        final comment = r['comment']?.toString() ?? '';
                        final created = DateTime.tryParse(
                                r['created_at']?.toString() ?? '') ??
                            DateTime.now();
                        final rating = r['rating'] is int
                            ? r['rating'] as int
                            : int.tryParse((r['rating'] ?? '').toString()) ?? 0;

                        return Row(
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
                                                  fontWeight:
                                                      FontWeight.bold))),
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
                                              i < rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Color.fromRGBO(
                                                  255, 203, 46, 1),
                                              size: 14))),
                                  const SizedBox(height: 6),
                                  Text(comment,
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
