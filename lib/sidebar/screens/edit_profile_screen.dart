import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Ichsan Simialakama');
  final _usernameController = TextEditingController(text: '@');
  final _emailController = TextEditingController(text: 'ichan.simialakama@example.com');

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildProfilePicture(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField('Nama', _nameController),
                    const SizedBox(height: 16),
                    _buildInputField('Username', _usernameController),
                    const SizedBox(height: 16),
                    _buildInputField('Email', _emailController),
                  ],
                ),
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
                    backgroundColor: AppColors.primary, // Ubah warna latar belakang menjadi merah
                    foregroundColor: Colors.white, // Ubah warna teks/ikon menjadi putih
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Membuat jarak antara teks dan ikon
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 160.0), // Geser teks ke kanan
                        child: const Text('Simpan'),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
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
                'Edit Profile',
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

  // Widget _buildProfilePicture() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 16.0),
  //     child: Center(
  //       child: Stack(
  //         children: [
  //           const CircleAvatar(
  //             radius: 48,
  //             backgroundImage: NetworkImage('https://via.placeholder.com/96'),
  //           ),
  //           Positioned(
  //             bottom: 0,
  //             right: 0,
  //             child: Container(
  //               width: 32,
  //               height: 32,
  //               decoration: const BoxDecoration(
  //                 color: AppColors.primary,
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Icon(
  //                 Icons.add,
  //                 color: Colors.white,
  //                 size: 20,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

Widget _buildProfilePicture() {
  return Column(
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Foto
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1503264116251-35a269479413?auto=format&fit=crop&w=800&q=80',
                ),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(0),
            ),
          ),
          // Tombol edit background
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          // Foto Profil
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        'assets/images/avatars/avatar3.jpg',
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 48), // Ruang setelah foto profil
    ],
  );
}






  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.grayLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
