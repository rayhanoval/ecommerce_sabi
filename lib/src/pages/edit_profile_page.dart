// lib/pages/edit_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

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
      if (row != null) {
        final map = Map<String, dynamic>.from(row as Map);
        setState(() {
          _usernameCtrl.text = map['username'] ?? '';
          _emailCtrl.text = user.email ?? '';
          _displayCtrl.text = map['display_name'] ?? map['full_name'] ?? '';
          _bioCtrl.text = map['bio'] ?? '';
          _phoneCtrl.text = map['phone'] ?? '';
          _addressCtrl.text = map['address'] ?? '';
          _avatarUrl = map['avatar_url'];
        });
      } else {
        // fallback: still fill email & username from auth if available
        setState(() {
          _emailCtrl.text = user.email ?? '';
        });
      }
    } catch (e) {
      // ignore load errors for now, but print for debugging
      print('loadProfile error: $e');
    }
  }

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final picked = await p.pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _pickedFile = File(picked.path);
    });
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

    // upload avatar if user picked one
    if (_pickedFile != null) {
      final url =
          await ProfileService.uploadAvatar(_pickedFile!, userId: user.id);
      if (url != null) uploadedUrl = url;
    }

    final ok = await ProfileService.updateProfile(
      user.id,
      displayName: _displayCtrl.text.trim(),
      username: _usernameCtrl.text
          .trim(), // usually read-only but still send if present
      bio: _bioCtrl.text.trim(),
      avatarUrl: uploadedUrl,
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')));
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // avatar preview + pick
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

              // 1. USERNAME (read-only)
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

              // 2. EMAIL (read-only)
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

              // 3. DISPLAY NAME
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

              // 4. BIO
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

              // 5. PHONE NUMBER
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

              // 6. ADDRESS
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
    );
  }
}
