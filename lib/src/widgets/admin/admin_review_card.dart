import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../widgets/review_image_gallery.dart';

class AdminReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final VoidCallback? onReplySuccess;

  const AdminReviewCard({
    super.key,
    required this.review,
    this.onReplySuccess,
  });

  @override
  State<AdminReviewCard> createState() => _AdminReviewCardState();
}

class _AdminReviewCardState extends State<AdminReviewCard> {
  bool _isReplying = false;
  bool _isSubmitting = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final reviewId = widget.review['id'];
      await Supabase.instance.client.from('product_ratings').update({
        'reply': _replyController.text.trim(),
        'reply_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply submitted successfully')),
        );
        setState(() {
          _isReplying = false;
          _replyController.clear();
        });
        widget.onReplySuccess?.call();
      }
    } catch (e) {
      debugPrint('Error submitting reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit reply: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.review['products'];
    final productName =
        product != null ? (product['name'] ?? 'Unknown') : 'Unknown';
    final productPrice = product != null ? (product['price'] ?? 0) : 0;
    final productImg = product != null ? (product['img_url'] ?? '') : '';

    // Check if 'products' is a list or map (Supabase join can vary)
    // Adjust based on actual data structure if needed.
    // Assuming standard join returns single object for 1-1 or N-1.

    final rating = widget.review['rating'] ?? 0;
    final comment = widget.review['comment'] ?? '';
    final reply = widget.review['reply'];

    final rawImage = widget.review['image_url']?.toString();
    List<String> images = [];
    if (rawImage != null && rawImage.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawImage);
        if (decoded is List) {
          images = decoded.map((e) => e.toString()).toList();
        } else {
          images = [rawImage];
        }
      } catch (_) {
        images = [rawImage];
      }
    }

    final formattedPrice =
        NumberFormat.currency(locale: 'id_ID', symbol: 'RP.', decimalDigits: 0)
            .format(productPrice);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white10,
                  image: productImg.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(productImg),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName.toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '1X', // Quantity not always available in review join, hardcoded as per design or need join with order_items
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Review Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'REVIEW',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.white,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    comment,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '-------------------------',
                    style: TextStyle(color: Colors.white54, letterSpacing: 2),
                  ),
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ReviewImageGallery(
                    images: images,
                    heroTagPrefix: widget.review['id'].toString(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Reply Section
          if (reply != null && reply.toString().isNotEmpty) ...[
            // Existing Reply
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'SABI ADMIN',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle,
                            color: Colors.blue, size: 14),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reply,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_isReplying) ...[
            // Reply Input
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _replyController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type your reply...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isReplying = false),
                          child: const Text(
                            'CLOSE',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'REPLY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Reply Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => setState(() => _isReplying = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'REPLY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
