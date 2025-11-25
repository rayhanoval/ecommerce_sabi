// lib/pages/edit_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../utils/image_cache_helper.dart';
import 'package:flutter/services.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final SupabaseClient _client = Supabase.instance.client;

  final TextEditingController _displayCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

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

      _emailCtrl.text = user.email ?? '';

      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        final map = Map<String, dynamic>.from(row as Map);

        setState(() {
          _displayCtrl.text = map['display_name'] ?? '';
          _bioCtrl.text = map['bio'] ?? '';
          _phoneCtrl.text = map['phone'] ?? '';
          _addressCtrl.text = map['default_address'] ?? '';
          _avatarUrl = map['avatar_url'] ?? '';
          _pickedFile = null;
        });
      } else {
        setState(() {
          _avatarUrl = null;
          _pickedFile = null;
        });
      }
    } catch (e, st) {
      debugPrint("loadProfile error: $e\n$st");
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() => _pickedFile = File(picked.path));
    } catch (e) {
      debugPrint("pickImage error: $e");
    }
  }

  Future<void> _save() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint("Save error: user not logged in");
      return;
    }

    setState(() => _loading = true);

    String? uploadedUrl = _avatarUrl;

    // Upload avatar
    if (_pickedFile != null) {
      final res = await ProfileService.uploadAvatarFile(
        _pickedFile!,
        userId: user.id,
      );

      if (res['ok'] == true && res['url'] != null) {
        final url = res['url'];
        uploadedUrl = url is String ? url : url.toString();
      } else {
        debugPrint("Upload gagal: ${res['error']}");
        setState(() => _loading = false);
        return;
      }
    }

    // Update profile
    final result = await ProfileService.updateProfile(
      user.id,
      displayName: _displayCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      defaultAddress: _addressCtrl.text.trim(),
      avatarUrl: uploadedUrl,
    );

    setState(() => _loading = false);

    if (result['ok'] == true) {
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        try {
          await ImageCacheHelper.evictImageByUrl(uploadedUrl);
        } catch (e) {
          debugPrint("evictImage error: $e");
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      debugPrint("Update profile error: ${result['error']}");
    }
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Widget _avatarWidget(double radius) {
    if (_pickedFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(_pickedFile!),
        backgroundColor: Colors.white12,
      );
    }

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_avatarUrl!),
        onBackgroundImageError: (_, __) {},
        backgroundColor: Colors.white12,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white12,
      child: const Icon(
        Icons.camera_alt_outlined,
        color: Colors.white54,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
          title: const Text(
            "Edit Profile",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SafeArea(
            child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: _avatarWidget(48),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text(
                        "Change avatar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // HANYA ANGKA
                      ],
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
                      maxLines: 2,
                      keyboardType: TextInputType.streetAddress,
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
                        : GestureDetector(
                            onTap: _save,
                            child: Image.asset(
                              'assets/images/save_button.png',
                              width: 220,
                              height: 120,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        )));
  }
}
