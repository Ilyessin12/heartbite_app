import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp.dart';

class VerifMethodPage extends StatefulWidget {
  const VerifMethodPage({super.key});

  @override
  _VerifMethodPageState createState() => _VerifMethodPageState();
}

class _VerifMethodPageState extends State<VerifMethodPage> {
  int _selectedMethod = -1; // -1 = belum dipilih, 0 = kiri, 1 = kanan

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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        16,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Tombol back kecil
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Ink(
                              decoration: const ShapeDecoration(
                                color: Color(0xFF8E1616),
                                shape: CircleBorder(),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20, // Ukuran ikon lebih kecil
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.075,
                        ),

                        // Judul
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Metode',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Verifikasi',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),

                        // Deskripsi
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Silakan pilih metode verifikasi untuk mengatur ulang kata sandi akun Anda.',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.dmSans(fontSize: 14),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),

                        // Tombol pilihan metode
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.20,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedMethod = 1;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _selectedMethod == 0 ||
                                                  _selectedMethod == -1
                                              ? const Color(
                                                0xFF8E1616,
                                              ).withOpacity(0.22)
                                              : const Color(0xFF462F4D),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.apple, size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Metode A',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.20,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedMethod = 0;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _selectedMethod == 1 ||
                                                  _selectedMethod == -1
                                              ? const Color(
                                                0xFF8E1616,
                                              ).withOpacity(0.22)
                                              : const Color(0xFF462F4D),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.apple, size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Metode B',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.30,
                        ),

                        // Tombol Lanjutkan
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const OtpPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8E1616),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Lanjutkan',
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
