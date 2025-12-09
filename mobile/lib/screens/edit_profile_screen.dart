import 'dart:io';

import 'package:community/models/user.dart';
import 'package:community/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _photoUrlController;
  final ApiService _apiService = ApiService();
  bool _saving = false;
  String? _localImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _photoUrlController = TextEditingController(text: widget.user.photoUrl ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();
    final photoUrl = _photoUrlController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username cannot be empty')));
      return;
    }

    setState(() => _saving = true);

    final fields = <String, dynamic>{'username': username};
    if (bio.isNotEmpty) fields['bio'] = bio;
    if (photoUrl.isNotEmpty) fields['photo_url'] = photoUrl;

    // If a new local image was selected, upload it first
    if (_localImagePath != null) {
      final uploadedUrl = await _apiService.uploadUserAvatar(widget.user.id, _localImagePath!);
      if (uploadedUrl != null) {
        fields['photo_url'] = uploadedUrl;
      }
    }

    final updated = await _apiService.updateUserProfile(widget.user.id, fields);
    setState(() => _saving = false);
    if (!mounted) return;
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop(updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientBackground,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white24,
                backgroundImage: _localImagePath != null
                    ? FileImage(File(_localImagePath!))
                    : (widget.user.photoUrl != null ? NetworkImage(widget.user.photoUrl!) as ImageProvider : null),
                child: _localImagePath == null && widget.user.photoUrl == null
                    ? const Icon(Icons.person, size: 48, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _photoUrlController,
              decoration: const InputDecoration(labelText: 'Photo URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving ? const CircularProgressIndicator() : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _localImagePath = picked.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }
}
