import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeartbiteScreen extends StatefulWidget {
  const HeartbiteScreen({super.key});

  @override
  State<HeartbiteScreen> createState() => _HeartbiteScreenState();
}

class _HeartbiteScreenState extends State<HeartbiteScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const _CustomSidebarDrawer(),
      appBar: AppBar(
        title: const Text('Heartbite'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: const Center(
        child: Text(
          'Heartbite',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}


class _CustomSidebarDrawer extends StatelessWidget {
  const _CustomSidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'I',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Ichsan Khandullah',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Suka memasak dan berbagi resep',
                        style: TextStyle(
                          color: AppColors.grayDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildMenuItem(context, icon: Icons.person, title: 'Profil', route: '/profile'),
            _buildMenuItem(context, icon: Icons.bookmark, title: 'Bookmark', route: '/bookmark'),
            _buildMenuItem(context, icon: Icons.settings, title: 'Pengaturan', route: '/settings'),
            _buildMenuItem(context, icon: Icons.info, title: 'About', route: '/about'),
          ],
        ),
      ),
    );
  }

  static Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String title, required String route}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Tutup drawer
        Navigator.pushNamed(context, route); // Arahkan ke halaman
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
