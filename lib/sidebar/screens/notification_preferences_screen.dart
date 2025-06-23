import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/setting_item.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _newMenuFromFollowing = true;
  bool _likesOnPosts = false;
  bool _comments = true;
  bool _isLoading = true;

  // Keys untuk SharedPreferences
  static const String _keyNewMenuFromFollowing = 'new_menu_from_following';
  static const String _keyLikesOnPosts = 'likes_on_posts';
  static const String _keyComments = 'comments';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Memuat preferensi dari SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _newMenuFromFollowing = prefs.getBool(_keyNewMenuFromFollowing) ?? true;
        _likesOnPosts = prefs.getBool(_keyLikesOnPosts) ?? false;
        _comments = prefs.getBool(_keyComments) ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading preferences: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Menyimpan preferensi ke SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNewMenuFromFollowing, _newMenuFromFollowing);
      await prefs.setBool(_keyLikesOnPosts, _likesOnPosts);
      await prefs.setBool(_keyComments, _comments);
      
      // Tampilkan notifikasi berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferensi notifikasi berhasil disimpan'),
          backgroundColor: AppColors.primary,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      print('Error saving preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan preferensi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Menyimpan secara otomatis saat ada perubahan
  Future<void> _updatePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('Error updating preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                children: [
                  SettingItem(
                    title: 'Menu baru dari following',
                    trailing: Switch(
                      value: _newMenuFromFollowing,
                      onChanged: (value) {
                        setState(() {
                          _newMenuFromFollowing = value;
                        });
                        // Simpan otomatis saat diubah
                        _updatePreference(_keyNewMenuFromFollowing, value);
                      },
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                  SettingItem(
                    title: 'Like pada postingan resep',
                    trailing: Switch(
                      value: _likesOnPosts,
                      onChanged: (value) {
                        setState(() {
                          _likesOnPosts = value;
                        });
                        // Simpan otomatis saat diubah
                        _updatePreference(_keyLikesOnPosts, value);
                      },
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                  SettingItem(
                    title: 'Komentar',
                    trailing: Switch(
                      value: _comments,
                      onChanged: (value) {
                        setState(() {
                          _comments = value;
                        });
                        // Simpan otomatis saat diubah
                        _updatePreference(_keyComments, value);
                      },
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 160.0),
                        child: Text('Simpan'),
                      ),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Preferensi Notifikasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}