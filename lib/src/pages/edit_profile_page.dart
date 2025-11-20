// lib/pages/edit_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../utils/image_cache_helper.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _client = Supabase.instance.client;

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _displayCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _avatarUrl;
  File? _pickedFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final id = user.id;

      final row =
          await _client.from('profiles').select().eq('id', id).maybeSingle();
      debugPrint('loadProfile row: $row');

      if (row != null) {
        final map = Map<String, dynamic>.from(row as Map);
        setState(() {
          _usernameCtrl.text = map['username'] ?? '';
          _emailCtrl.text = user.email ?? '';
          _displayCtrl.text = map['display_name'] ?? map['full_name'] ?? '';
          _bioCtrl.text = map['bio'] ?? '';
          _phoneCtrl.text = map['phone'] ?? '';
          // use default_address per DB schema
          _addressCtrl.text = map['default_address'] ?? '';
          _avatarUrl = map['avatar_url'];
          _pickedFile = null;
        });
      } else {
        setState(() {
          _emailCtrl.text = user.email ?? '';
          _usernameCtrl.text = '';
          _avatarUrl = null;
          _pickedFile = null;
        });
      }
    } catch (e, st) {
      debugPrint('loadProfile error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final p = ImagePicker();
      final picked = await p.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() {
        _pickedFile = File(picked.path);
      });
    } catch (e) {
      debugPrint('pickImage error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  Future<void> _save() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    setState(() => _loading = true);

    String? uploadedUrl = _avatarUrl;

    // 1) upload avatar jika user memilih file
    if (_pickedFile != null) {
      final uploadRes =
          await ProfileService.uploadAvatar(_pickedFile!, userId: user.id);
      debugPrint('uploadRes: $uploadRes');

      if (uploadRes['ok'] == true && uploadRes['url'] != null) {
        final url = uploadRes['url'];
        if (url is String && url.isNotEmpty) {
          uploadedUrl = url;
        } else {
          uploadedUrl = url.toString();
        }
      } else {
        final err = uploadRes['error'] ?? 'Unknown upload error';
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Avatar upload failed: $err')));
        return;
      }
    }

    // 2) upsert profile ke DB — perhatikan: updateProfile mengembalikan Map
    final result = await ProfileService.updateProfile(
      user.id,
      displayName: _displayCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      avatarUrl: uploadedUrl,
      phone: _phoneCtrl.text.trim(),
      defaultAddress: _addressCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );

    debugPrint('updateProfile result: $result');

    setState(() => _loading = false);

    if (result['ok'] == true) {
      // sukses — evict cache kalau ada uploadedUrl
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        try {
          await ImageCacheHelper.evictImageByUrl(uploadedUrl);
        } catch (e) {
          debugPrint('evictImage error: $e');
        }
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final err = result['error'] ?? 'Unknown error while updating profile';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $err')));
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _displayCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () async {
              await _loadProfile();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Refreshed')));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white12,
                    backgroundImage: _pickedFile != null
                        ? FileImage(_pickedFile!)
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(_avatarUrl!) as ImageProvider
                            : null),
                    child: (_pickedFile == null &&
                            (_avatarUrl == null || _avatarUrl!.isEmpty))
                        ? const Icon(Icons.camera_alt_outlined,
                            color: Colors.white54, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: _pickImage, child: const Text('Change avatar')),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _usernameCtrl,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _displayCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                              horizontal: s.width * 0.12, vertical: 14),
                        ),
                        child: const Text('Save'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
