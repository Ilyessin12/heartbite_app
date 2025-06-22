import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/profile_screen.dart';
import '../../bookmark/screens/bookmark_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SidebarScreen extends StatefulWidget {
  const SidebarScreen({super.key});

  @override
  State<SidebarScreen> createState() => _SidebarScreenState();
}

class _SidebarScreenState extends State<SidebarScreen> {
  String? _userProfilePictureUrl;
  String _userName = 'Loading...';
  StreamSubscription<AuthState>? _authSubscription;
  
  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    
    // Listen for auth state changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      // Update profile data when auth state changes
      _fetchUserProfile();
    });
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
  
  // Fetch user profile data from Supabase
  Future<void> _fetchUserProfile() async {
    if (AuthService.isUserLoggedIn()) {
      try {
        // Get profile picture
        final profilePicUrl = await AuthService.getUserProfilePicture();
        
        // Get other user data
        final userService = UserService();
        final userProfile = await userService.getCurrentUserProfile();
          if (mounted) {
          setState(() {
            _userProfilePictureUrl = profilePicUrl;
            _userName = userProfile?['full_name'] ?? userProfile?['username'] ?? 'No Name';
          });
        }
      } catch (e) {
        print("Error fetching user profile in sidebar: $e");
      }
    } else {      if (mounted) {
        setState(() {
          _userProfilePictureUrl = null;
          _userName = 'Guest';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Profile picture from Supabase or default avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: _userProfilePictureUrl != null && _userProfilePictureUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_userProfilePictureUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                      color: _userProfilePictureUrl == null || _userProfilePictureUrl!.isEmpty 
                          ? AppColors.primary 
                          : null,
                    ),
                    child: _userProfilePictureUrl == null || _userProfilePictureUrl!.isEmpty
                      ? Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : null,
                  ),                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: 'Profil',
              destination: const ProfileScreen(),
            ),
            _buildMenuItem(
              context,
              icon: Icons.bookmark,
              title: 'Bookmark',
              destination: const BookmarkScreen(),
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings,
              title: 'Pengaturan',
              destination: const SettingsScreen(),
            ),            _buildMenuItem(
              context,
              icon: Icons.info,
              title: 'About',
              destination: const AboutScreen(),
            ),
            const Spacer(),
            const Divider(height: 1),
            // Sign out button
            AuthService.isUserLoggedIn()
              ? InkWell(
                  onTap: () async {
                    await AuthService.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You have been signed out')),
                      );
                      Navigator.pop(context); // Close the drawer
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: const Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
