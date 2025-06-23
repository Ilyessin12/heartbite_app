import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Sesuaikan path import sesuai dengan struktur folder Anda
import '../bottomnavbar/bottom-navbar.dart';
import '../services/notification_service.dart';
import '../services/supabase_client.dart';
import 'model/notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedIndex = 3; // Karena ini halaman notifikasi, index 3 dipilih
  bool _hasNotifications = false;
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();
  final List<Map<String, dynamic>> _notifikasiBelumDibaca = [];
  final List<Map<String, dynamic>> _notifikasiSudahDibaca = [];
  
  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }
  
  @override
  void dispose() {
    _notificationService.unsubscribeFromUserNotifications();
    super.dispose();
  }  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Ambil ID pengguna yang sedang login
      final User? currentUser = SupabaseClientWrapper().auth.currentUser;
      print('Current user: ${currentUser?.id}');
      
      if (currentUser != null) {
        print('Fetching notifications for user: ${currentUser.id}');
        
        // Ambil notifikasi dari Supabase
        final notifications = await _notificationService.fetchUserNotifications(currentUser.id);
        print('Fetched ${notifications.length} notifications');
        
        // Kelompokkan notifikasi berdasarkan status dibaca
        final groupedNotifications = _notificationService.groupNotificationsByReadStatus(notifications);
        
        setState(() {
          _notifikasiBelumDibaca.clear();
          _notifikasiSudahDibaca.clear();
            // Use null check operator with empty list fallback
          _notifikasiBelumDibaca.addAll(groupedNotifications['unread'] ?? []);
          _notifikasiSudahDibaca.addAll(groupedNotifications['read'] ?? []);
            // For debugging, always show notifications UI
          _hasNotifications = true; 
          _isLoading = false;
          
          // If no notifications were found, add test data
          if (_notifikasiBelumDibaca.isEmpty && _notifikasiSudahDibaca.isEmpty) {
            _addTestNotificationData();
          }
          
          print('UI updated with ${_notifikasiBelumDibaca.length} unread and ${_notifikasiSudahDibaca.length} read notifications');
          print('_hasNotifications set to: $_hasNotifications');
        });
        
        // Subscribe untuk pembaruan realtime
        _notificationService.subscribeToUserNotifications(currentUser.id, (updatedNotifications) {
          final groupedUpdated = _notificationService.groupNotificationsByReadStatus(updatedNotifications);
              
          setState(() {
            _notifikasiBelumDibaca.clear();
            _notifikasiSudahDibaca.clear();
              _notifikasiBelumDibaca.addAll(groupedUpdated['unread'] ?? []);
            _notifikasiSudahDibaca.addAll(groupedUpdated['read'] ?? []);
            
            // For debugging, always show notifications UI
            _hasNotifications = true;
          });
        });
      } else {
        print('No current user found');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
    // Menangani ketika notifikasi diklik
  void _handleNotificationTap(Map<String, dynamic> notification) async {
    // Tandai notifikasi sebagai sudah dibaca jika belum
    if (notification['dibaca'] == false) {
      await _notificationService.markNotificationAsRead(notification['id']);
      
      // Update tampilan
      setState(() {
        notification['dibaca'] = true;
        _notifikasiBelumDibaca.remove(notification);
        _notifikasiSudahDibaca.insert(0, notification);
      });
    }
    
    // Navigate berdasarkan tipe notifikasi
    final bool canNavigate = notification['canNavigate'] ?? false;
    if (canNavigate) {
      final String? route = notification['navigationRoute'];
      final Map<String, dynamic>? args = notification['navigationArgs'];
      
      if (route != null) {
        // Navigate to the appropriate page
        Navigator.of(context).pushNamed(route, arguments: args);
      }
    }
  }
  
  // Function to debug time format of notifications
  void _showTimeDebugInfo(BuildContext context) {
    if (_notifikasiBelumDibaca.isEmpty && _notifikasiSudahDibaca.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada notifikasi untuk ditampilkan')),
      );
      return;
    }
    
    final Map<String, dynamic> notifikasi = 
      _notifikasiBelumDibaca.isNotEmpty ? _notifikasiBelumDibaca[0] : _notifikasiSudahDibaca[0];
      
    // Get notification info from Supabase again to see the raw value
    _getNotificationRawTime(notifikasi['id']).then((rawInfo) {
      if (rawInfo != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Informasi Waktu'),
            content: SingleChildScrollView(              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ID Notifikasi: ${notifikasi['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  Divider(),
                  Text('Notifikasi dibuat:'),
                  Text('Format UI: ${notifikasi['waktu']}'),
                  SizedBox(height: 4),
                  Text('Raw dari DB: ${notifikasi['raw_created_at'] ?? 'Tidak tersedia'}'),
                  SizedBox(height: 4),
                  Text('Waktu Lokal: ${notifikasi['local_time'] ?? 'Tidak tersedia'}'),
                  Divider(),
                  Text('Detail Waktu dari Supabase:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Waktu di Database (UTC):'),
                  Text(rawInfo['created_at'] ?? 'Tidak tersedia', style: TextStyle(fontFamily: 'Courier')),
                  SizedBox(height: 8),
                  Text('Waktu Lokal:'),
                  Text(rawInfo['local_time'] ?? 'Tidak tersedia', style: TextStyle(fontFamily: 'Courier')),
                  SizedBox(height: 8),
                  Text('Zona Waktu Perangkat:'),
                  Text(rawInfo['timezone_info'] ?? 'Tidak tersedia'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil informasi waktu notifikasi')),
        );
      }
    });
  }
    // Get raw time information from a notification
  Future<Map<String, String>?> _getNotificationRawTime(int notificationId) async {
    try {
      final response = await SupabaseClientWrapper().client
        .from('notifications')
        .select('created_at')
        .eq('id', notificationId)
        .single();
      
      if (response.containsKey('created_at')) {
        final String createdAtUtc = response['created_at'];
        final DateTime utcTime = DateTime.parse(createdAtUtc);
        final DateTime localTime = utcTime.toLocal();
        
        return {
          'created_at': createdAtUtc,
          'local_time': '${localTime.toString()} (${localTime.timeZoneName})',
          'timezone_info': 'Offset: ${localTime.timeZoneOffset.inHours} jam ${localTime.timeZoneOffset.inMinutes % 60} menit',
        };
      }
      return null;
    } catch (e) {
      print('Error getting notification time info: $e');
      return null;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index != 3) { // Jika bukan halaman notifikasi
      // Kembali ke halaman sebelumnya jika menekan tombol lain
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFF8E1616);
    
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
                      Navigator.pop(context); // Kembali ke halaman sebelumnya
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
                    ),                  ),
                    const Spacer(),
                  
                  
                  // Tombol refresh
                  IconButton(
                    onPressed: _fetchNotifications,
                    icon: Icon(
                      Icons.refresh,
                      color: primaryRed,
                    ),
                  ),
                ],
              ),
            ),
              // Konten: Tampilkan loading indicator, notifikasi atau tampilan kosong
            Expanded(
              child: _isLoading ? _buildLoadingView() :
                (_notifikasiBelumDibaca.isNotEmpty || _notifikasiSudahDibaca.isNotEmpty) ? 
                  // Tampilan dengan notifikasi
                  _buildNotificationListView(_notifikasiBelumDibaca, _notifikasiSudahDibaca) : 
                  // Tampilan kosong
                  _buildEmptyNotificationView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        onFabPressed: () {
          // Handle the FAB button press (create recipe)
          // If needed, navigate to create recipe page
          Navigator.pop(context); // First go back to homepage
          // Then the homepage can handle the navigation to create recipe
        },
      ),
    );
  }  // Widget untuk menampilkan daftar notifikasi
  Widget _buildNotificationListView(
      List<Map<String, dynamic>> notifikasiBelumDibaca, 
      List<Map<String, dynamic>> notifikasiSudahDibaca) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0), // Diperkecil dari 24.0 untuk margin yang lebih efisien
      children: [
        
        // Bagian belum dibaca
        if (notifikasiBelumDibaca.isNotEmpty) ...[
          const SizedBox(height: 20), // Diperkecil dari 24
          Row(
            children: [
              Text(
                'Belum Dibaca',
                style: GoogleFonts.dmSans(
                  fontSize: 16, // Diperkecil dari 18
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E1616),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifikasiBelumDibaca.length}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12, // Diperkecil dari 14
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Diperkecil dari 16
          
          // Notifikasi belum dibaca
          ...notifikasiBelumDibaca.map((notifikasi) => 
            _buildNotificationItem(notifikasi, false)
          ).toList(),
        ],
        
        // Bagian sudah dibaca
        if (notifikasiSudahDibaca.isNotEmpty) ...[
          const SizedBox(height: 24), // Tetap 24 untuk jarak antar section
          Text(
            'Sudah Dibaca',
            style: GoogleFonts.dmSans(
              fontSize: 16, // Diperkecil dari 18
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // Diperkecil dari 16
          
          // Notifikasi sudah dibaca
          ...notifikasiSudahDibaca.map((notifikasi) => 
            _buildNotificationItem(notifikasi, true)
          ).toList(),
        ],
        
        // Padding bawah
        const SizedBox(height: 20), // Diperkecil dari 24
      ],
    );
  }

  // Widget untuk menampilkan tampilan kosong
  Widget _buildEmptyNotificationView() {
    return Column(
      children: [
        // Empty space
        const Spacer(flex: 1),
        
        // Empty notification illustration
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Image.asset(
            'assets/images/empty_notif_illustration.png',
            height: 300,
            fit: BoxFit.contain,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // "No notifications yet" text
        Text(
          'Belum ada Notifikasi',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Empty space
        const Spacer(flex: 2),
      ],
    );
  }
    // Widget untuk menampilkan loading indicator
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFF8E1616),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat notifikasi...',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
    // Mendapatkan warna ikon berdasarkan tipe notifikasi
  Color _getNotificationIconColor(String tipe) {
    if (tipe.startsWith('like')) {
      return const Color(0xFFFF4848); // Merah untuk like
    } else if (tipe.startsWith('komentar')) {
      return const Color(0xFF4285F4); // Biru untuk komentar
    } else if (tipe == 'follow') {
      return const Color(0xFF34A853); // Hijau untuk follow
    } else {
      return const Color(0xFF9E9E9E); // Abu-abu untuk lainnya
    }
  }  Widget _buildNotificationItem(Map<String, dynamic> notifikasi, bool dibaca) {
    // Debug info
    print('Building notification item: ${notifikasi['id']} (${notifikasi['tipe']})');
    
    // Warna latar belakang untuk notifikasi yang belum dibaca
    final Color bgColor = dibaca ? Colors.white : const Color(0xFFFFF2F2);
      // Mendapatkan icon berdasarkan tipe notifikasi
    IconData? iconTipe;
    final String notificationType = notifikasi['tipe'] ?? 'other';
    print('Notification type: $notificationType');
    
    switch (notificationType) {
      case 'like_resep':
        iconTipe = Icons.favorite;
        break;
      case 'like_komentar':
        iconTipe = Icons.favorite;
        break;
      case 'follow':
        iconTipe = Icons.person_add;
        break;
      case 'komentar_resep':
        iconTipe = Icons.comment;
        break;
      case 'komentar_komentar':
        iconTipe = Icons.comment;
        break;
      default:
        iconTipe = Icons.notifications;
        break;
    }
    
    // Menentukan apakah ini kasus mutual follow
    final bool isMutualFollow = notifikasi['tipe'] == 'follow' && 
                                notifikasi.containsKey('isFollowingYou') && 
                                notifikasi['isFollowingYou'] == true;
      // Handler for notification taps
    return GestureDetector(
      onTap: () => _handleNotificationTap(notifikasi),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!dibaca)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto profil dengan badge ikon tipe notifikasi
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: notifikasi['gambarProfil'].toString().startsWith('http') 
                      ? NetworkImage(notifikasi['gambarProfil']) as ImageProvider
                      : AssetImage(notifikasi['gambarProfil']),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    height: 18,
                    width: 18,                    decoration: BoxDecoration(
                      color: _getNotificationIconColor(notifikasi['tipe']),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        iconTipe,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 10),
            
            // Konten notifikasi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama dan aksi
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: dibaca ? FontWeight.normal : FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: notifikasi['nama'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: dibaca ? Colors.black : const Color(0xFF8E1616),
                          ),
                        ),
                        TextSpan(
                          text: ' ${notifikasi['aksi']}',
                        ),
                      ],
                    ),
                  ),
                  
                  // Berbagai subteks berdasarkan tipe notifikasi
                  if (notifikasi['tipe'] == 'like_resep')
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        notifikasi['targetNama'],
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                  if (notifikasi['tipe'] == 'like_komentar')
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        '"${notifikasi['targetNama']}" ${notifikasi['subteks']}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  
                  if (notifikasi.containsKey('subteks') && 
                     (notifikasi['tipe'] == 'komentar_resep' || 
                      notifikasi['tipe'] == 'komentar_komentar'))
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        notifikasi['subteks'],
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                    ),                  if (notifikasi['tipe'] == 'komentar_komentar')
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        notifikasi['targetNama'],
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    
                  // Waktu
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Text(
                      notifikasi['waktu'],
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 10),
            
            // Konten sisi kanan berdasarkan tipe notifikasi
            if (notifikasi['adaGambar'])
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: notifikasi['gambarKonten'].toString().startsWith('http')
                  ? Image.network(
                      notifikasi['gambarKonten'],
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Image.asset('assets/images/default_food.png', width: 65, height: 65, fit: BoxFit.cover),
                    )
                  : Image.asset(
                      notifikasi['gambarKonten'],
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                    ),
              )
            else if (notifikasi['tipe'] == 'follow' && !isMutualFollow)
              GestureDetector(
                onTap: () {
                  // TODO: Implementasi follow back
                },
                child: Container(
                  height: 36,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E1616),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Ikuti',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else if (isMutualFollow)
              Container(
                height: 36,
                width: 80,
                decoration: BoxDecoration(                color: Colors.transparent,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                'Mengikuti',
                style: GoogleFonts.dmSans(
                  color: Colors.black87,
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
    // Debug function to add test notification data
  void _addTestNotificationData() {
    print('Adding test notification data');
    
    // Test like_recipe notification (basic)
    _notifikasiSudahDibaca.add({
      'id': 9999,
      'nama': 'Test User',
      'waktu': '23/06/2025 14:30',
      'gambarProfil': 'assets/images/default_profile.png',
      'dibaca': true,
      'tipe': 'like_resep',
      'aksi': 'menyukai resep Anda',
      'adaGambar': true,
      'targetNama': 'Test Recipe',
      'gambarKonten': 'assets/images/default_food.png',
      'canNavigate': false,
      'recipeId': 12345,
    });
    
    // Test like_recipe notification with network image
    _notifikasiSudahDibaca.add({
      'id': 9997,
      'nama': 'Network User',
      'waktu': '22/06/2025 12:30',
      'gambarProfil': 'assets/images/default_profile.png',
      'dibaca': true,
      'tipe': 'like_resep',
      'aksi': 'menyukai resep Anda',
      'adaGambar': true,
      'targetNama': 'Recipe With Network Image',
      // Use a placeholder image URL that will likely fail to load, triggering the error handler
      'gambarKonten': 'https://example.com/nonexistent-image.jpg',
      'canNavigate': false,
      'recipeId': 67890,
    });
    
    // Test follow notification
    _notifikasiBelumDibaca.add({
      'id': 9998,
      'nama': 'Follow User',
      'waktu': '22/06/2025 10:15',
      'gambarProfil': 'assets/images/default_profile.png',
      'dibaca': false,
      'tipe': 'follow',
      'aksi': 'telah mengikuti Anda',
      'adaGambar': false,
      'adaTombolIkuti': true,
      'isFollowingYou': false,
      'canNavigate': false,
    });
      // Test direct comment on recipe notification
    _notifikasiBelumDibaca.add({
      'id': 9996,
      'nama': 'Direct Comment User',
      'waktu': '21/06/2025 09:45',
      'gambarProfil': 'assets/images/default_profile.png',
      'dibaca': false,
      'tipe': 'komentar_resep',
      'aksi': 'mengomentari resep Anda:',
      'adaGambar': true,
      'targetNama': 'Ayam Bakar Special',
      'gambarKonten': 'assets/images/default_food.png',
      'subteks': 'Ini komentar langsung pada resep Anda. Resepnya sangat lezat dan mudah diikuti!',
      'canNavigate': false,
      'recipeId': 54321,
    });
    
    // Test reply to comment notification
    _notifikasiBelumDibaca.add({
      'id': 9995,
      'nama': 'Reply Comment User',
      'waktu': '20/06/2025 15:30',
      'gambarProfil': 'assets/images/default_profile.png',
      'dibaca': false,
      'tipe': 'komentar_komentar',
      'aksi': 'membalas komentar Anda:',
      'adaGambar': true,
      'targetNama': 'komentar Anda',
      'gambarKonten': 'assets/images/default_food.png',
      'subteks': 'Terima kasih atas responnya! Saya akan mencoba saran modifikasi bumbu tersebut.',
      'canNavigate': false,
      'recipeId': 54321,
    });
    
    print('Added ${_notifikasiSudahDibaca.length} read and ${_notifikasiBelumDibaca.length} unread test notifications');
  }
}