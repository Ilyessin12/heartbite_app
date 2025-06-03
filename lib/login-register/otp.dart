import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'resetPass.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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
                        // Back Button (kecil)
                        Row(
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
                                  size: 20, // Ukuran kecil
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
                            'Kode OTP',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Deskripsi
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Silakan periksa email/SMS Anda untuk melihat pesan yang berisi kode OTP. Kode terdiri dari 4 angka.',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.dmSans(fontSize: 14),
                          ),
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.035,
                        ),

                        // Input OTP
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E1616).withOpacity(0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width * 0.15,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  autofocus: index == 0,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: GoogleFonts.dmSans(fontSize: 20),
                                  decoration: const InputDecoration(
                                    hintText: '—',
                                    counterText: "",
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 3) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                        ),

                        const Spacer(),

                        // Tombol Lanjutkan
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              final otp =
                                  _controllers.map((c) => c.text).join();
                              print('OTP: $otp');

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ResetPassPage(),
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
