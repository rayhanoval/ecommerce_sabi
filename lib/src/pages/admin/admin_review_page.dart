import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce_sabi/src/widgets/admin/admin_review_card.dart';

class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key});

  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _refreshReviews() async {
    await _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final res = await _client
          .from('product_ratings')
          .select('*, products(*), users(display_name, username)')
          .filter('reply', 'is', null)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> loaded = [];
      for (var r in res) {
        loaded.add(Map<String, dynamic>.from(r));
      }

      if (mounted) {
        setState(() {
          _reviews = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/sabi_login.png',
          height: 24,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'ALL REVIEWS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _reviews.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refreshReviews,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Text(
                                'No reviews yet',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshReviews,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return AdminReviewCard(
                            review: review,
                            onReplySuccess: _fetchReviews,
                          );
                        },
                      ),
          ),
      )],
      ),
    );
  }
}
