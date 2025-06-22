import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../homepage/homepage.dart';
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
  
  // Username availability status
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String _usernameMessage = '';
  
  // Timer untuk debounce
  Timer? _debounceTimer;

  // Tambahkan controller di sini
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Menambahkan listener pada username controller
    _usernameController.addListener(_onUsernameChanged);
  }    @override
  void dispose() {
    // Membersihkan timer dan controller
    _debounceTimer?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
    // Fungsi untuk mengecek ketersediaan username dengan delay
  void _onUsernameChanged() {
    // Batalkan timer sebelumnya jika ada
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    // Jika username kosong, reset status
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameMessage = '';
      });
      return;
    }
    
    // Mulai timer baru (2 detik)
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      // Tampilkan loading
      setState(() {
        _isCheckingUsername = true;
        _usernameMessage = 'Memeriksa ketersediaan username...';
      });
      
      try {
        final UserService userService = UserService();
        final isAvailable = await userService.isUsernameAvailable(_usernameController.text.trim());
        
        if (!mounted) return;
        
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = isAvailable;
          _usernameMessage = isAvailable 
              ? 'Username tersedia!'
              : 'Username sudah digunakan, silakan pilih yang lain';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = null;
          _usernameMessage = 'Gagal memeriksa username';
        });
      }
    });
  }

  // Validasi semua field
  bool _validateFields() {
    if (_emailController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Semua field wajib diisi!';
      });
      return false;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _statusMessage = 'Kata sandi tidak cocok!';
      });
      return false;
    }
    
    // Validasi username availability jika sudah dicek
    if (_isUsernameAvailable == false) {
      setState(() {
        _statusMessage = 'Username sudah digunakan, silakan pilih yang lain';
      });
      return false;
    }
    
    return true;
  }

  // Dialog sukses registrasi dengan petunjuk konfirmasi email
  void _showSuccessRegistrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Registrasi Berhasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Silakan cek email Anda untuk melakukan konfirmasi akun.'),
            SizedBox(height: 12),
            Text('Setelah konfirmasi, Anda bisa kembali ke aplikasi dan langsung masuk ke akun Anda.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
            },
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
              _tryLoginAfterConfirmation(); // Coba login setelah konfirmasi
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8E1616),
            ),
            child: Text('Saya sudah konfirmasi email'),
          ),
        ],
      ),
    );
  }

  // Dialog untuk email yang sudah terdaftar tapi perlu konfirmasi
  void _showEmailConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Email Sudah Terdaftar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email ini sudah terdaftar tetapi mungkin belum dikonfirmasi.'),
            SizedBox(height: 8),
            Text('Silakan cek email Anda untuk link konfirmasi.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tryLoginAfterConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8E1616),
            ),
            child: Text('Saya sudah konfirmasi email'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mencoba login setelah konfirmasi
  Future<void> _tryLoginAfterConfirmation() async {
    setState(() {
      _statusMessage = 'Mencoba login setelah konfirmasi...';
    });
    
    try {
      final userService = UserService();
      final signInRes = await userService.signIn(
        email: _emailController.text.trim(), 
        password: _passwordController.text
      );
      
      if (signInRes.user != null) {
        // Login berhasil, arahkan ke HomePage
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SetupAllergiesPage()),
          (route) => false,
        );
      } else {
        setState(() {
          _statusMessage = 'Login gagal setelah konfirmasi.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Login gagal';
        _showEmailConfirmationDialog();
      });
    }
  }

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
                                SizedBox(height: 12),                                TextField(
                                  controller:
                                      _usernameController, // Tambahkan ini
                                  style: GoogleFonts.dmSans(),
                                  decoration: InputDecoration(
                                    hintText: 'username',
                                    prefixIcon: Container(
                                      width: 50,
                                      alignment: Alignment.center,
                                      child: Row(
                                        children: [
                                          SizedBox(width: 10),
                                          Text(
                                            '@',
                                            style: GoogleFonts.dmSans(
                                              color: Colors.grey,
                                              fontSize: 18, // Ukuran @ lebih besar
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Container(
                                            height: 24,
                                            width: 1,
                                            color: Colors.grey.withOpacity(0.5), // Sekat vertikal
                                          ),
                                        ],
                                      ),
                                    ),
                                    suffixIcon: _isCheckingUsername
                                      ? Container(
                                          width: 24,
                                          height: 24,
                                          padding: EdgeInsets.all(6),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : _isUsernameAvailable == null
                                        ? null
                                        : _isUsernameAvailable!
                                          ? Icon(Icons.check_circle, color: Colors.green)
                                          : Icon(Icons.cancel, color: Colors.red),
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
                                if (_usernameMessage.isNotEmpty)
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.only(left: 8, top: 4),
                                    child: Text(
                                      _usernameMessage,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isUsernameAvailable == null
                                            ? Colors.grey
                                            : _isUsernameAvailable!
                                                ? Colors.green
                                                : Colors.red,
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
                              ],
                            ),
                          ),
                        ),
                        // Tombol daftar
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                            SizedBox(height: 8),
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
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(                                onPressed: () async {
                                  setState(() {
                                    _statusMessage = '';
                                  });

                                  // Validasi semua field dan password match
                                  if (!_validateFields()) return;
                                  
                                  try {
                                    final userService = UserService();
                                    
                                    // Cek dulu apakah username tersedia
                                    final username = _usernameController.text.trim().startsWith('@')
                                        ? _usernameController.text.trim().substring(1)
                                        : _usernameController.text.trim();
                                    
                                    final isAvailable = await userService.isUsernameAvailable(username);
                                    
                                    if (!isAvailable) {
                                      setState(() {
                                        _statusMessage = 'Username sudah digunakan, silakan pilih yang lain';
                                      });
                                      return;
                                    }
                                    
                                    // Cek apakah email sudah terdaftar sebelum pendaftaran
                                    try {
                                      final emailExistsCheck = await userService.checkEmailExists(_emailController.text.trim());
                                      
                                      if (emailExistsCheck) {
                                        setState(() {
                                          _statusMessage = 'Email sudah terdaftar. Silakan login atau konfirmasi email Anda.';
                                          _showEmailConfirmationDialog();
                                        });
                                        return;
                                      }
                                    } catch (e) {
                                      // Lanjutkan dengan pendaftaran jika gagal memeriksa email
                                      print('Error checking email');
                                    }
                                    
                                    // Registrasi user baru jika email belum terdaftar
                                    final signUpRes = await userService.signUp(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                      username: username,
                                      fullName: _fullNameController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                    );
                                    
                                    if (signUpRes.user != null) {
                                      if (!mounted) return;
                                      
                                      // Tampilkan halaman sukses dengan instruksi konfirmasi email
                                      _showSuccessRegistrationDialog();
                                      setState(() {
                                        _statusMessage = 'Registrasi berhasil! Silakan cek email untuk konfirmasi.';
                                      });
                                    } else {
                                      setState(() {
                                        _statusMessage = 'Registrasi gagal: Tidak dapat membuat user.';
                                      });
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    
                                    // Tangani error spesifik Supabase
                                    if (e.toString().contains('User already registered')) {
                                      setState(() {
                                        _statusMessage = 'Email sudah terdaftar. Silakan konfirmasi email atau coba login.';
                                      });
                                      
                                      // Tambahkan tombol untuk cek konfirmasi atau login
                                      _showEmailConfirmationDialog();
                                    } else {
                                      setState(() {
                                        _statusMessage = 'Registrasi gagal: $e';
                                      });
                                    }
                                  }
                                  
                                  // Log untuk debugging
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
