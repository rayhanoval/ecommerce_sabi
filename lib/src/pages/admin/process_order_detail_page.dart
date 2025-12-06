import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class ProcessOrderDetailPage extends StatefulWidget {
  final List<String> orderIds;

  const ProcessOrderDetailPage({
    super.key,
    required this.orderIds,
  });

  @override
  State<ProcessOrderDetailPage> createState() => _ProcessOrderDetailPageState();
}

class _ProcessOrderDetailPageState extends State<ProcessOrderDetailPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isShipping = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _client
          .from('orders')
          .select(
              '*, order_items(*, products(*)), users!fk_orders_profiles(display_name, phone)')
          .filter('id', 'in', widget.orderIds);

      final List<Map<String, dynamic>> loaded = [];
      for (var r in res) {
        loaded.add(Map<String, dynamic>.from(r));
      }

      if (mounted) {
        setState(() {
          _orders = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching order details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAsPdf() async {
    setState(() => _isSaving = true);
    try {
      final pdf = pw.Document();

      for (var order in _orders) {
        final orderId = order['id']?.toString() ?? '';
        final shippingAddress = order['shipping_address']?.toString() ?? '';
        final items = (order['order_items'] as List?) ?? [];

        // Get user data from join
        final userData = order['users'];
        final name = userData != null ? (userData['display_name'] ?? '') : '';
        final phone = userData != null ? (userData['phone'] ?? '') : '';

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: pw.Text(
                        'SABI',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Divider(),
                    pw.SizedBox(height: 20),
                    pw.Text('ORDER ID: $orderId',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('NAME: $name'),
                    pw.Text('ADDRESS: $shippingAddress'),
                    pw.Text('PHONE: $phone'),
                    pw.SizedBox(height: 20),
                    pw.Divider(),
                    pw.SizedBox(height: 20),
                    ...items.map((item) {
                      final product = item['products'];
                      final productName =
                          product != null ? (product['name'] ?? '') : '';
                      final quantity = item['quantity'] ?? 0;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text('PRODUCT NAME: $productName'),
                            ),
                            pw.Text('ORDER QUANTITY: ${quantity}X'),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'orders_$timestamp.pdf';

      if (kIsWeb) {
        // Web platform: trigger browser download
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF downloaded: $fileName')),
          );
        }
      } else {
        // Native platform: save to Downloads folder
        Directory? directory;

        if (Platform.isAndroid) {
          // Android: use Downloads directory
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          // iOS: use Documents directory (iOS doesn't have public Downloads)
          directory = await getApplicationDocumentsDirectory();
        } else {
          // Desktop: use Downloads directory
          directory = await getDownloadsDirectory();
        }

        if (directory != null) {
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(pdfBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF saved to ${file.path}')),
            );
          }
        } else {
          throw Exception('Could not find downloads directory');
        }
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _markAsShipped() async {
    setState(() => _isShipping = true);
    try {
      await _client
          .from('orders')
          .update({'status': 'shipped'}).filter('id', 'in', widget.orderIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orders marked as shipped')),
        );
        // Don't navigate back, just refresh the data
        _fetchOrderDetails();
      }
    } catch (e) {
      debugPrint('Error marking as shipped: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as shipped: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isShipping = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _OrderCard(order: order);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _saveAsPdf,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SAVE AS PDF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isShipping ? null : _markAsShipped,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _isShipping
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'MARK AS SHIPPED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order['id']?.toString() ?? '';
    final shippingAddress = order['shipping_address']?.toString() ?? '';
    final items = (order['order_items'] as List?) ?? [];

    // Get user data from join
    final userData = order['users'];
    final name = userData != null ? (userData['display_name'] ?? '') : '';
    final phone = userData != null ? (userData['phone'] ?? '') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/sabi_putih.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          _buildInfoRow('ORDER ID', orderId),
          _buildInfoRow('NAME', name),
          _buildInfoRow('ADDRESS', shippingAddress),
          _buildInfoRow('PHONE', phone),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          ...items.map((item) {
            final product = item['products'];
            final productName = product != null ? (product['name'] ?? '') : '';
            final quantity = item['quantity'] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'PRODUCT NAME: ${productName.toString().toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    '${quantity}X',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
