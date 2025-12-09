import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class SocialMediaSettingsScreen extends StatefulWidget {
  const SocialMediaSettingsScreen({super.key});

  @override
  State<SocialMediaSettingsScreen> createState() =>
      _SocialMediaSettingsScreenState();
}

class _SocialMediaSettingsScreenState extends State<SocialMediaSettingsScreen> {
  final Map<String, TextEditingController> _controllers = {
    'instagram': TextEditingController(),
    'twitter': TextEditingController(),
    'facebook': TextEditingController(),
    'tiktok': TextEditingController(),
    'youtube': TextEditingController(),
  };

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveSocialMedia() {
    // TODO: Implement API call to save social media accounts
    final socialMedia = Map<String, String>.fromEntries(
      _controllers.entries
          .where((entry) => entry.value.text.isNotEmpty)
          .map((entry) => MapEntry(entry.key, entry.value.text)),
    );

    // For now, just show a success message and log the payload
    debugPrint('Social media payload: $socialMedia');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Social media accounts saved!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientBackground,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Container(
                  decoration: AppTheme.glassmorphismDecoration,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Social Media Settings",
                        style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Connect your social media accounts to let attendees follow you directly.",
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      _buildSocialMediaField(
                        'Instagram',
                        'instagram',
                        Icons.camera_alt,
                        'https://instagram.com/',
                      ),
                      const SizedBox(height: 20),
                      _buildSocialMediaField(
                        'Twitter',
                        'twitter',
                        Icons.chat,
                        'https://twitter.com/',
                      ),
                      const SizedBox(height: 20),
                      _buildSocialMediaField(
                        'Facebook',
                        'facebook',
                        Icons.facebook,
                        'https://facebook.com/',
                      ),
                      const SizedBox(height: 20),
                      _buildSocialMediaField(
                        'TikTok',
                        'tiktok',
                        Icons.music_note,
                        'https://tiktok.com/@',
                      ),
                      const SizedBox(height: 20),
                      _buildSocialMediaField(
                        'YouTube',
                        'youtube',
                        Icons.play_circle_fill,
                        'https://youtube.com/@',
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _saveSocialMedia,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text(
                          "Save Settings",
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaField(
      String label, String key, IconData icon, String prefix) {
    return TextField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter your $label username',
        prefixIcon: Icon(icon, color: Colors.white70),
        prefixText: prefix,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}
