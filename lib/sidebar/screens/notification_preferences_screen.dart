import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
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
                      },
                      activeColor: AppColors.primary, // Thumb merah saat ON
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
                      },
                      activeColor: AppColors.primary, // Thumb merah saat ON
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
                      },
                      activeColor: AppColors.primary, // Thumb merah saat ON
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Merah sesuai theme
                    foregroundColor: Colors.white,      // Warna teks putih
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                    Padding(
                      padding: EdgeInsets.only(left: 160.0), // Geser teks ke kanan 8 pixel
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
          const SizedBox(width: 32), // For balance
        ],
      ),
    );
  }
}
