import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/setting_item.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

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
                    title: 'Negara',
                    onTap: () => Navigator.pushNamed(context, '/settings/country'),
                  ),
                  SettingItem(
                    title: 'Preferensi Notifikasi',
                    onTap: () => Navigator.pushNamed(context, '/settings/notifications'),
                  ),
                  SettingItem(
                    title: 'Mode Malam',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                          color: _isDarkMode ? Colors.indigo : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isDarkMode,
                          onChanged: (value) {
                            setState(() {
                              _isDarkMode = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SettingItem(
                    title: 'Tentang Aplikasi',
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Merah sesuai theme
                    foregroundColor: Colors.white,      // Warna teks putih
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Logout Akun'),
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
                'Pengaturan',
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
