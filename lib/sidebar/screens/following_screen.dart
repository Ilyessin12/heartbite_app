import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/user_list_item.dart';

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> followingUsers = [
      {
        'name': 'Sandy Chase',
        'username': '@sandychase',
        'avatarUrl': 'assets/images/avatars/avatar1.jpg',
      },
      {
        'name': 'Eleanor Langdon',
        'username': '@eleanorlan',
        'avatarUrl': 'assets/images/avatars/avatar2.jpg',
      },
      {
        'name': 'Salid Snake',
        'username': '@salidsnake',
        'avatarUrl': 'assets/images/avatars/avatar3.jpg',
      },
      {
        'name': 'Zidan Hadid',
        'username': '@zidanhadid',
        'avatarUrl': 'assets/images/avatars/avatar4.jpg',
      },
      {
        'name': 'Kevin Sanjaya',
        'username': '@kevinsanjaya',
        'avatarUrl': 'assets/images/avatars/avatar5.jpg',
      },
      {
        'name': 'I AM STEVE',
        'username': '@steve',
        'avatarUrl': 'assets/images/avatars/avatar2.jpg',
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.builder(
                itemCount: followingUsers.length,
                itemBuilder: (context, index) {
                  final user = followingUsers[index];
                  return UserListItem(
                    name: user['name'],
                    username: user['username'],
                    avatarUrl: user['avatarUrl'],
                    onFollowTap: () {},
                  );
                },
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
                'Following',
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
