import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAddressPage extends StatefulWidget {
  const EditAddressPage({super.key});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedId;
  bool _loading = false;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _fetching = true;
    });
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() {
          _addresses = [];
          _fetching = false;
        });
        return;
      }
      // Try reading from "addresses" table; fallback to address in users if table missing
      final res = await _client
          .from('addresses')
          .select()
          .eq('user_id', user.id)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: false);

      if (res is List && res.isNotEmpty) {
        _addresses = (res).map((e) => Map<String, dynamic>.from(e)).toList();
        _selectedId = _addresses
            .firstWhere((a) => a['is_primary'] == true,
                orElse: () => _addresses.first)['id']
            ?.toString();
      } else {
        // fallback: try address in users
        final prof = await _client
            .from('users')
            .select('address, display_name, phone')
            .eq('id', user.id)
            .maybeSingle();
        final map = prof != null ? Map<String, dynamic>.from(prof as Map) : {};
        final def = (map['address'] ?? '').toString();
        if (def.isNotEmpty) {
          _addresses = [
            {
              'id': 'profile_default',
              'user_id': user.id,
              'name': map['display_name'] ?? '',
              'phone': map['phone'] ?? '',
              'address': def,
              'is_primary': true
            }
          ];
          _selectedId = 'profile_default';
        } else {
          _addresses = [];
          _selectedId = null;
        }
      }
    } catch (e) {
      debugPrint('fetchAddresses error: $e');
      _addresses = [];
      _selectedId = null;
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _setPrimary(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      // set all to false then set chosen to true
      await _client
          .from('addresses')
          .update({'is_primary': false}).eq('user_id', user.id);
      await _client.from('addresses').update({'is_primary': true}).eq('id', id);
      // optionally update users.address for convenience
      final chosen = _addresses.firstWhere((a) => a['id'].toString() == id);
      await _client
          .from('users')
          .update({'address': chosen['address']}).eq('id', user.id);
      await _fetchAddresses();
      setState(() => _selectedId = id);
    } catch (e) {
      debugPrint('setPrimary error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAddress(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await _client.from('addresses').delete().eq('id', id);
      await _fetchAddresses();
    } catch (e) {
      debugPrint('deleteAddress error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddAddress() async {
    // open simple add address page and refresh afterwards
    final res = await Navigator.of(context).push<Map<String, dynamic>?>(
        MaterialPageRoute(builder: (_) => const _AddAddressPage()));
    if (res != null) {
      await _fetchAddresses();
      setState(() {
        _selectedId = res['id']?.toString();
      });
    }
  }

  Widget _tagChip(String? tag) {
    if (tag == null || tag.toString().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(6)),
      child: Text(tag.toString(),
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color.fromRGBO(255, 202, 46, 1);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Pilih Alamat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _openAddAddress,
            tooltip: 'Tambah alamat baru',
          )
        ],
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _fetchAddresses,
              child: _addresses.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 40),
                        Center(
                            child: Text('Belum ada alamat tersimpan',
                                style: TextStyle(color: Colors.white54))),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Alamat Baru'),
                            onPressed: _openAddAddress,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.black),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (ctx, idx) {
                        final a = _addresses[idx];
                        final id = a['id']?.toString() ?? idx.toString();
                        final name = (a['name'] ?? '').toString();
                        final phone = (a['phone'] ?? '').toString();
                        final address = (a['address'] ?? '').toString();
                        final isPrimary = a['is_primary'] == true ||
                            a['is_primary']?.toString() == 'true';
                        final tag = a['tag']?.toString();

                        return InkWell(
                          onTap: () {
                            // select and return chosen address
                            Navigator.of(context).pop(a);
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Radio<String>(
                                value: id,
                                groupValue: _selectedId,
                                onChanged: (v) async {
                                  if (v == null) return;
                                  // if it's special profile_default id, just set local selection
                                  if (id == 'profile_default') {
                                    setState(() => _selectedId = id);
                                    Navigator.of(context).pop(a);
                                    return;
                                  }
                                  await _setPrimary(id);
                                  Navigator.of(context).pop(a);
                                },
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(
                                              name.isNotEmpty ? name : 'Nama',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      TextButton(
                                          onPressed: () {
                                            // TODO: navigate to edit single address page (not implemented) - for now open add page with prefill
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                                    builder: (_) =>
                                                        _AddAddressPage(
                                                            prefill: a)))
                                                .then((_) => _fetchAddresses());
                                          },
                                          child: const Text('Ubah',
                                              style: TextStyle(
                                                  color: Colors.white70))),
                                    ]),
                                    if (phone.isNotEmpty)
                                      Text(phone,
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                    const SizedBox(height: 6),
                                    Text(address,
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (isPrimary)
                                          Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: accent,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              child: const Text('Utama',
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12))),
                                        const SizedBox(width: 6),
                                        _tagChip(tag),
                                        const Spacer(),
                                        if (id != 'profile_default')
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white54),
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  backgroundColor: Colors.black,
                                                  title: const Text(
                                                      'Hapus alamat?',
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: const Text(
                                                            'Batal')),
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: const Text(
                                                            'Hapus')),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await _deleteAddress(id);
                                              }
                                            },
                                          )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12),
                      itemCount: _addresses.length,
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAddress,
        label: const Text('Tambah Alamat Baru'),
        icon: const Icon(Icons.add),
        backgroundColor: accent,
        foregroundColor: Colors.black,
      ),
    );
  }
}

/// Simple add/edit address page used by EditAddressPage.
/// If prefill provided, we use it to update (upsert).
class _AddAddressPage extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const _AddAddressPage({this.prefill});

  @override
  State<_AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<_AddAddressPage> {
  final _client = Supabase.instance.client;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isPrimary = false;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  String? _tag;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      final p = widget.prefill!;
      _nameCtrl.text = (p['name'] ?? '').toString();
      _phoneCtrl.text = (p['phone'] ?? '').toString();
      _addressCtrl.text = (p['address'] ?? '').toString();
      _isPrimary =
          p['is_primary'] == true || p['is_primary']?.toString() == 'true';
      _tag = p['tag']?.toString();
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = _client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'user_id': user.id,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'is_primary': _isPrimary,
        'tag': _tag,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (widget.prefill != null && widget.prefill!['id'] != null) {
        // update
        await _client
            .from('addresses')
            .update(payload)
            .eq('id', widget.prefill!['id']);
        // if is_primary true, set users.address too
        if (_isPrimary) {
          await _client
              .from('users')
              .update({'address': _addressCtrl.text.trim()}).eq('id', user.id);
        }
        Navigator.of(context).pop(payload..['id'] = widget.prefill!['id']);
      } else {
        // insert
        final inserted = await _client
            .from('addresses')
            .insert(payload)
            .select()
            .maybeSingle();
        final row = inserted == null
            ? null
            : Map<String, dynamic>.from(
                (inserted as Map).cast<String, dynamic>());
        if (row != null && _isPrimary) {
          await _client
              .from('users')
              .update({'address': _addressCtrl.text.trim()}).eq('id', user.id);
        }
        Navigator.of(context).pop(row);
      }
    } catch (e) {
      debugPrint('save address error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan alamat')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color.fromRGBO(255, 202, 46, 1);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            Text(widget.prefill != null ? 'Ubah Alamat' : 'Tambah Alamat Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Nama',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'No. Telepon',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Alamat lengkap',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Alamat wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _tag,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Tag (mis. Alamat Toko)',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10),
                  onChanged: (v) => _tag = v,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                        value: _isPrimary,
                        activeColor: accent,
                        onChanged: (v) =>
                            setState(() => _isPrimary = v ?? false)),
                    const SizedBox(width: 6),
                    const Text('Jadikan utama',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accent, foregroundColor: Colors.black),
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : const Text('Simpan Alamat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
