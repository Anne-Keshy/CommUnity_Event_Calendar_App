import 'package:community/services/api_service.dart';
import 'package:community/services/auth_service.dart';
import 'package:community/models/user.dart';
import 'edit_profile_screen.dart';
import 'package:flutter/material.dart';
// flutter_animate removed from this file — animations not required here
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  // Optional userId to view other profiles; null means current user's profile.
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isFollowing = false;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  User? _profileUser;
  bool _isOwner = false;
  bool _loading = true;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  void _toggleFollow() async {
    bool success;
    if (_profileUser == null) return;

    final targetId = _profileUser!.id;
    if (_isFollowing) {
      success = await _apiService.unfollowUser(targetId);
      if (success) {
        setState(() {
          _isFollowing = false;
          // remove current user's id from followers (optimistic)
          _profileUser!.followers.removeWhere((id) => id == _profileUser!.id);
        });
      }
    } else {
      success = await _apiService.followUser(targetId);
      if (success) {
        setState(() {
          _isFollowing = true;
          // optimistic: we don't know current user's id here; keep UI toggle
        });
      }
    }

    if (!success) {
      debugPrint("Follow/Unfollow request was queued due to network issues.");
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }


  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final currentUser = await _apiService.getUserProfile();

      if (widget.userId != null) {
        final profile = await _apiService.getUserById(widget.userId!);
        setState(() {
          _profileUser = profile;
          _isOwner = (currentUser != null && profile != null && currentUser.id == profile.id);
          _isFollowing = currentUser != null && profile != null && currentUser.following.contains(profile.id);
        });
      } else {
        setState(() {
          _profileUser = currentUser;
          _isOwner = true;
          _isFollowing = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _loading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : (_profileUser == null
                    ? const SizedBox(height: 300, child: Center(child: Text('Profile not found')))
                    : LayoutBuilder(builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.glassmorphismDecoration,
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left column: avatar + basic info
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            children: [
                                              Stack(
                                                alignment: Alignment.bottomRight,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 80,
                                                    backgroundColor: Colors.white24,
                                                    backgroundImage: _profileUser!.photoUrl != null
                                                        ? NetworkImage(_profileUser!.photoUrl!)
                                                        : null,
                                                    child: _profileUser!.photoUrl == null
                                                        ? const Icon(Icons.person, size: 96, color: Colors.white)
                                                        : null,
                                                  ),
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Material(
                                                      color: AppTheme.primaryColor,
                                                      shape: const CircleBorder(),
                                                      child: IconButton(
                                                        icon: const Icon(Icons.edit, color: Colors.white),
                                                        onPressed: () async {
                                                          final updated = await Navigator.of(context).push<User?>(
                                                            MaterialPageRoute(
                                                              builder: (_) => EditProfileScreen(user: _profileUser!),
                                                            ),
                                                          );
                                                          if (!mounted) return;
                                                          if (updated != null) setState(() => _profileUser = updated);
                                                        },
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(_profileUser!.username,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                              const SizedBox(height: 6),
                                              Text('@${_profileUser!.username}', style: GoogleFonts.poppins(color: Colors.white70)),
                                              const SizedBox(height: 12),
                                              if ((_profileUser!.bio ?? '').isNotEmpty)
                                                Text(_profileUser!.bio!, style: GoogleFonts.poppins(color: Colors.white70), textAlign: TextAlign.center),
                                              const SizedBox(height: 20),
                                              isWide
                                                  ? const SizedBox.shrink()
                                                  : const SizedBox(height: 12),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        // Right column: stats + actions
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  _buildStatColumn("Followers", _profileUser!.followers.length.toString()),
                                                  _buildStatColumn("Following", _profileUser!.following.length.toString()),
                                                  _buildStatColumn("Events", "12"),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              _isOwner
                                                  ? ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.white,
                                                        foregroundColor: AppTheme.primaryColor,
                                                        minimumSize: const Size.fromHeight(50),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      onPressed: () async {
                                                        final updated = await Navigator.of(context).push<User?>(
                                                          MaterialPageRoute(
                                                            builder: (_) => EditProfileScreen(user: _profileUser!),
                                                          ),
                                                        );
                                                        if (!mounted) return;
                                                        if (updated != null) setState(() => _profileUser = updated);
                                                      },
                                                      child: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                                    )
                                                  : ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: _isFollowing ? Colors.grey[200] : Colors.white,
                                                        foregroundColor: AppTheme.primaryColor,
                                                        minimumSize: const Size.fromHeight(50),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      onPressed: _toggleFollow,
                                                      child: Text(_isFollowing ? 'Following' : 'Follow', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                                    ),
                                              const SizedBox(height: 12),
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white70,
                                                  side: const BorderSide(color: Colors.white24),
                                                  minimumSize: const Size.fromHeight(50),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                onPressed: _logout,
                                                child: Text('Logout', style: GoogleFonts.poppins()),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            CircleAvatar(
                                              radius: 80,
                                              backgroundColor: Colors.white24,
                                              backgroundImage: _profileUser!.photoUrl != null ? NetworkImage(_profileUser!.photoUrl!) : null,
                                              child: _profileUser!.photoUrl == null ? const Icon(Icons.person, size: 96, color: Colors.white) : null,
                                            ),
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Material(
                                                color: AppTheme.primaryColor,
                                                shape: const CircleBorder(),
                                                child: IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.white),
                                                  onPressed: () async {
                                                    final updated = await Navigator.of(context).push<User?>(
                                                      MaterialPageRoute(
                                                        builder: (_) => EditProfileScreen(user: _profileUser!),
                                                      ),
                                                    );
                                                    if (!mounted) return;
                                                    if (updated != null) setState(() => _profileUser = updated);
                                                  },
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(_profileUser!.username, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 6),
                                        Text('@${_profileUser!.username}', style: GoogleFonts.poppins(color: Colors.white70)),
                                        const SizedBox(height: 12),
                                        if ((_profileUser!.bio ?? '').isNotEmpty) Text(_profileUser!.bio!, style: GoogleFonts.poppins(color: Colors.white70), textAlign: TextAlign.center),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildStatColumn("Followers", _profileUser!.followers.length.toString()),
                                            _buildStatColumn("Following", _profileUser!.following.length.toString()),
                                            _buildStatColumn("Events", "12"),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        _isOwner
                                            ? ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: AppTheme.primaryColor,
                                                  minimumSize: const Size.fromHeight(50),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                onPressed: () async {
                                                  final updated = await Navigator.of(context).push<User?>(
                                                    MaterialPageRoute(
                                                      builder: (_) => EditProfileScreen(user: _profileUser!),
                                                    ),
                                                  );
                                                  if (!mounted) return;
                                                  if (updated != null) setState(() => _profileUser = updated);
                                                },
                                                child: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                              )
                                            : ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _isFollowing ? Colors.grey[200] : Colors.white,
                                                  foregroundColor: AppTheme.primaryColor,
                                                  minimumSize: const Size.fromHeight(50),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                onPressed: _toggleFollow,
                                                child: Text(_isFollowing ? 'Following' : 'Follow', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                              ),
                                        const SizedBox(height: 12),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white70,
                                            side: const BorderSide(color: Colors.white24),
                                            minimumSize: const Size.fromHeight(50),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: _logout,
                                          child: Text('Logout', style: GoogleFonts.poppins()),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      })),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
