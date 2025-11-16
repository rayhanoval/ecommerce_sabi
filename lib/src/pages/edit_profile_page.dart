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
  final _displayCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _avatarUrl;
  File? _pickedFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final id = user.id;
    final rows =
        await _client.from('profiles').select().eq('id', id).maybeSingle();
    if (rows != null) {
      final map = Map<String, dynamic>.from(rows);
      setState(() {
        _displayCtrl.text = map['display_name'] ?? map['full_name'] ?? '';
        _usernameCtrl.text = map['username'] ?? '';
        _bioCtrl.text = map['bio'] ?? '';
        _avatarUrl = map['avatar_url'];
      });
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
    if (_pickedFile != null) {
      final url =
          await ProfileService.uploadAvatar(_pickedFile!, userId: user.id);
      if (url != null) uploadedUrl = url;
    }

    final ok = await ProfileService.updateProfile(
      user.id,
      displayName: _displayCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      avatarUrl: uploadedUrl,
    );

    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: const Text('Edit Profile'), backgroundColor: Colors.black),
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
              TextFormField(
                controller: _displayCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Display name',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10),
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
                    fillColor: Colors.white10),
              ),

              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Text('Save')),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
