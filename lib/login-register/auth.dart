import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register.dart';
import 'login.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});
  @override
  AuthPage createState() {
    return AuthPage();
  }
}

class AuthPage extends State<Auth> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return MaterialApp(
      title: 'Auth Page',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  // Using a Container with ClipRect and OverflowBox to zoom the image
                  Container(
                    height: screenHeight * 0.65,
                    width: double.infinity,
                    child: ClipRect(
                      child: OverflowBox(
                        maxHeight: screenHeight * 1.0, // Larger than container
                        maxWidth: double.infinity,
                        child: Image.asset(
                          'assets/images/login/start.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center, // You can adjust this to focus on different parts
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: screenHeight * 0.65,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.5), // Black overlay with 50% opacity
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Akun',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ayo mulai perjalanan bersama HeartBite',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Add space to center the buttons between image bottom and screen bottom
              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8E1616),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mail_outlined),
                            SizedBox(width: 8),
                            Text(
                              'Daftar dengan email',
                              style: GoogleFonts.dmSans(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                // 8E1616 with 20% opacity
                                backgroundColor: Color(0xFF8E1616).withOpacity(0.2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Ink.image(
                                image: AssetImage(
                                  'assets/images/login/google.png',
                                ),
                                fit: BoxFit.cover,
                                height: 25,
                                width: 25,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                // 8E1616 with 20% opacity
                                backgroundColor: Color(0xFF8E1616).withOpacity(0.2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [Icon(Icons.apple, size: 32)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8E1616),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person),
                            SizedBox(width: 8),
                            Text(
                              'Lanjutkan sebagai Guest',
                              style: GoogleFonts.dmSans(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        'Punya akun? Login', 
                        style: GoogleFonts.dmSans(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
