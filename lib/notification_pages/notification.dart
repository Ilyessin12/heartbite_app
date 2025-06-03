import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Sesuaikan path import sesuai dengan struktur folder Anda
import '../bottomnavbar/bottom-navbar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedIndex = 3; // Karena ini halaman notifikasi, index 3 dipilih

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Navigasi ke halaman lain berdasarkan index yang dipilih
    // Ini hanya contoh, Anda perlu menyesuaikan dengan navigasi aplikasi Anda
    if (index != 3) { // Jika bukan halaman notifikasi
      // Contoh navigasi ke halaman lain
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => halamanTujuan),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFF8E1616);
    
    // Data notifikasi terbaru
    final List<Map<String, dynamic>> notifikasiTerbaru = [
      {
        'nama': 'Fernandez',
        'aksi': 'menyukai resep Anda',
        'waktu': '23 menit yang lalu',
        'adaGambar': true,
        'gambarProfil': 'assets/images/avatars/avatar1.jpg',
        'gambarKonten': 'assets/images/cookbooks/cake.jpg',
        'adaBanyakGambar': false,
        'adaTombolIkuti': false,
      },
      {
        'nama': 'Amanda',
        'aksi': 'telah mengikuti Anda kembali',
        'waktu': '2 jam yang lalu',
        'adaGambar': false,
        'gambarProfil': 'assets/images/avatars/avatar2.jpg',
        'adaBanyakGambar': false,
        'adaTombolIkuti': false,
      },
      {
        'nama': 'Michael',
        'aksi': 'Mengomentari resep Anda:',
        'subteks': 'Saya sudah mencobanya dan rasanya lezat!',
        'waktu': '4 jam yang lalu',
        'adaGambar': true,
        'gambarProfil': 'assets/images/avatars/avatar3.jpg',
        'gambarKonten': 'assets/images/cookbooks/chicken.jpg',
        'adaBanyakGambar': false,
        'adaTombolIkuti': false,
      },
    ];
    
    // Data notifikasi lama
    final List<Map<String, dynamic>> notifikasiLama = [
      {
        'nama': 'Patricia',
        'aksi': 'telah memposting resep barunya',
        'waktu': '1 hari yang lalu',
        'adaGambar': true,
        'gambarProfil': 'assets/images/avatars/avatar4.jpg',
        'gambarKonten': 'assets/images/recipes/sandwich1.jpg',
        'adaBanyakGambar': false,
        'adaTombolIkuti': false,
      },
    ];
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar dengan tombol kembali dan judul
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  // Tombol kembali dalam lingkaran merah
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryRed,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Judul
                  Text(
                    'Notifikasi',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Daftar notifikasi
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  // Bagian terbaru
                  const SizedBox(height: 24),
                  Text(
                    'Terbaru',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notifikasi terbaru
                  ...notifikasiTerbaru.map((notifikasi) => 
                    _buildNotificationItem(notifikasi)
                  ).toList(),
                  
                  // Bagian notifikasi lama
                  const SizedBox(height: 32),
                  Text(
                    'Notifikasi Lama',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notifikasi lama
                  ...notifikasiLama.map((notifikasi) => 
                    _buildNotificationItem(notifikasi)
                  ).toList(),
                  
                  // Padding bawah
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex, // Ubah dari selectedIndex menjadi currentIndex
        onTap: _onItemTapped, // Ubah dari onItemTapped menjadi onTap
      ),
    );
  }
  
  Widget _buildNotificationItem(Map<String, dynamic> notifikasi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto profil
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: AssetImage(notifikasi['gambarProfil']),
          ),
          
          const SizedBox(width: 12),
          
          // Konten notifikasi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama dan aksi
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: notifikasi['nama'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' ${notifikasi['aksi']}',
                      ),
                    ],
                  ),
                ),
                
                // Subteks jika tersedia
                if (notifikasi.containsKey('subteks'))
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      notifikasi['subteks'],
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                
                // Beberapa gambar untuk pembaruan galeri
                if (notifikasi['adaBanyakGambar'])
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: List.generate(3, (index) => 
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              notifikasi['gambarGaleri'][index],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      ),
                    ),
                  ),
                
                // Waktu
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    notifikasi['waktu'],
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Konten sisi kanan (gambar makanan atau tombol ikuti)
          if (notifikasi['adaGambar'])
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                notifikasi['gambarKonten'],
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            )
          else if (notifikasi['adaTombolIkuti'])
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_add,
                size: 20,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }
}