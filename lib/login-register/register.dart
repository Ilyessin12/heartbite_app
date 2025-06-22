import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../setup_pages/setupallergies.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Variabel untuk mengatur apakah password terlihat atau tidak
  bool _isPasswordVisible = false;

  // Status message for registration feedback
  String _statusMessage = '';

  // Tambahkan controller di sini
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decorative lines
          Positioned.fill(
            child: Image.asset(
              'assets/images/Ornament.png',
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: SingleChildScrollView(
                // memungkinkan scroll
                child: ConstrainedBox(
                  // agar tidak tak terbatas tingginya
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        16, // untuk menyamakan dengan padding vertikal total
                  ),
                  child: IntrinsicHeight(
                    // agar Column bisa mengatur tinggi anak-anaknya
                    child: Column(
                      children: [
                        // Baris atas: tombol back & login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Smaller back button
                            Container(
                              height: 36, // Reduced from default 48
                              width: 36, // Reduced from default 48
                              decoration: const ShapeDecoration(
                                color: Color(0xFF8E1616),
                                shape: CircleBorder(),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 18, // Reduced from default 24
                                ),
                                padding: EdgeInsets.zero, // Remove padding
                                constraints:
                                    BoxConstraints(), // Remove constraints
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  'Masuk',
                                  style: GoogleFonts.dmSans(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.075,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Daftar',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005,
                        ),
                        // Text field input
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Teks deskripsi rata kiri
                                TextField(
                                  controller: _emailController, // Tambahkan ini
                                  style: GoogleFonts.dmSans(),
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: GoogleFonts.dmSans(),
                                    filled: true,
                                    fillColor: Color.fromARGB(13, 0, 0, 0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller: _phoneController,
                                  style: GoogleFonts.dmSans(),
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: 'Nomor Telepon',
                                    hintStyle: GoogleFonts.dmSans(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Color.fromARGB(13, 0, 0, 0),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller:
                                      _fullNameController, // Tambahkan ini
                                  style: GoogleFonts.dmSans(),
                                  decoration: InputDecoration(
                                    hintText: 'Nama Lengkap',
                                    hintStyle: GoogleFonts.dmSans(),
                                    filled: true,
                                    fillColor: Color.fromARGB(13, 0, 0, 0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller:
                                      _usernameController, // Tambahkan ini
                                  style: GoogleFonts.dmSans(),
                                  decoration: InputDecoration(
                                    hintText: 'Username',
                                    hintStyle: GoogleFonts.dmSans(),
                                    filled: true,
                                    fillColor: Color.fromARGB(13, 0, 0, 0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller:
                                      _passwordController, // Tambahkan ini
                                  style: GoogleFonts.dmSans(),
                                  obscureText:
                                      !_isPasswordVisible, // Menyembunyikan atau menampilkan password
                                  decoration: InputDecoration(
                                    hintText: 'Kata Sandi',
                                    hintStyle: GoogleFonts.dmSans(),
                                    filled: true,
                                    fillColor: Color.fromARGB(13, 0, 0, 0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller:
                                      _confirmPasswordController, // Tambahkan ini
                                  style: GoogleFonts.dmSans(),
                                  obscureText:
                                      !_isPasswordVisible, // Menyembunyikan atau menampilkan password
                                  decoration: InputDecoration(
                                    hintText: 'Konfirmasi Kata Sandi',
                                    hintStyle: GoogleFonts.dmSans(),
                                    filled: true,
                                    fillColor: Color.fromARGB(13, 0, 0, 0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        // Tombol daftar
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width:
                                    MediaQuery.of(context).size.width *
                                    0.65, // Atur lebar sesuai kebutuhan
                                child: Text(
                                  'Dengan mendaftar Anda menyetujui Syarat dan Ketentuan kami',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(fontSize: 12),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            // ...existing code sebelum tombol daftar...
                            if (_statusMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  _statusMessage,
                                  style: TextStyle(
                                    color:
                                        _statusMessage.contains('berhasil')
                                            ? Colors.green
                                            : Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            // ...existing code tombol daftar...
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    _statusMessage = '';
                                  });

                                  // Validasi sederhana
                                  if (_emailController.text.isEmpty ||
                                      _fullNameController.text.isEmpty ||
                                      _usernameController.text.isEmpty ||
                                      _passwordController.text.isEmpty ||
                                      _phoneController.text.isEmpty) {
                                    setState(() {
                                      _statusMessage =
                                          'Semua field wajib diisi!';
                                    });
                                    return;
                                  }
                                  
                                  if (_passwordController.text !=
                                      _confirmPasswordController.text) {
                                    setState(() {
                                      _statusMessage =
                                          'Kata sandi tidak cocok!';
                                    });
                                    return;
                                  }

                                  try {
                                    final userService = UserService();
                                    final res = await userService.signUp(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                      username: _usernameController.text.trim(),
                                      fullName: _fullNameController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                    );
                                    setState(() {
                                      _statusMessage = 'Registrasi berhasil!';
                                    });

                                    // Tambahkan pengecekan login sebelum navigasi
                                    if (AuthService.isUserLoggedIn()) {
                                      // Jika user terdeteksi login, arahkan ke SetupAllergiesPage
                                      print('User terdeteksi login, mengarahkan ke setup allergies');
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SetupAllergiesPage(),
                                        ),
                                      );
                                    } else {
                                      // Jika user tidak terdeteksi login, tampilkan pesan error
                                      setState(() {
                                        _statusMessage = 'Registrasi berhasil tetapi login gagal. Silakan login manual.';
                                      });
                                      
                                      // Opsional: Arahkan ke halaman login
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginPage(),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setState(() {
                                      _statusMessage = 'Registrasi gagal: $e';
                                    });
                                  }
                                  print('Status login: ${AuthService.isUserLoggedIn()}');
                                  print('User ID: ${AuthService.getCurrentUserId()}');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8E1616),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Daftar',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
