import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'setupdiets.dart'; // Import setupdiets.dart for navigation
import '../services/supabase_client.dart'; // Import Supabase client
import '../services/auth_service.dart'; // Import AuthService untuk mengakses user ID

class SetupAllergiesPage extends StatefulWidget {
  const SetupAllergiesPage({Key? key}) : super(key: key);

  @override
  State<SetupAllergiesPage> createState() => _SetupAllergiesPageState();
}

class _SetupAllergiesPageState extends State<SetupAllergiesPage> {
  final Color primaryRed = const Color(0xFF8E1616);
  final _supabase = SupabaseClientWrapper().client;
  
  // Track selected allergies - now empty by default
  final Set<String> selectedAllergies = {};
  
  // List untuk menyimpan data alergi dari database
  List<Map<String, dynamic>> allergensList = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchAllergens();
  }
    // Fungsi untuk mengambil data alergi dari Supabase
  Future<void> fetchAllergens() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Ambil data dari tabel allergens, hanya nama yang kita perlukan
      final response = await _supabase
          .from('allergens')
          .select('name')
          .order('name');
      
      // Update state dengan data yang diterima
      setState(() {
        allergensList = List<Map<String, dynamic>>.from(response);
      });
      
      // Cek apakah user sudah login dan ambil alergi yang sudah dipilih
      await loadSelectedAllergies();
    } catch (e) {
      print('Error fetching allergens: $e');
      // Jika gagal mengambil data, gunakan data statis sebagai fallback
      setState(() {
        allergensList = [
          {'name': 'Gluten'}, 
          {'name': 'Produk Susu'}, 
          {'name': 'Telur'},
          {'name': 'Kedelai'}, 
          {'name': 'Kacang Tanah'}, 
          {'name': 'Gandum'},
          {'name': 'Susu'}, 
          {'name': 'Ikan'}
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
    // Fungsi untuk memuat alergi yang sudah dipilih oleh user
  Future<void> loadSelectedAllergies() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId != null) {        // Ambil alergi yang sudah dipilih user dari tabel user_allergens
        final userAllergensResponse = await _supabase
            .from('user_allergens')
            .select('allergens(name)')
            .eq('user_id', userId);
        
        if (userAllergensResponse.isNotEmpty) {
          final selectedNames = userAllergensResponse
              .map((item) => item['allergens']['name'] as String)
              .toSet();
          
          setState(() {
            selectedAllergies.addAll(selectedNames);
          });
          print('Loaded ${selectedNames.length} previously selected allergens');
        }
      }
    } catch (e) {
      print('Error loading selected allergens: $e');
      // Jika gagal, tidak masalah, user bisa pilih lagi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorative lines
          Positioned.fill(
            child: Image.asset(
              'assets/images/Ornament.png', // Placeholder for background pattern
              fit: BoxFit.contain, // Zoom out: seluruh gambar terlihat
              alignment: Alignment.topLeft, // Posisikan di kiri atas
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Top row with back arrow, progress indicator, and skip button
                  Row(
                    children: [
                      // Back arrow in red circle
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
                          alignment: Alignment.center, // Memusatkan anak (Icon)
                          child: const Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: Colors.white, // Kontras dengan lingkaran merah
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Progress indicator
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.3, // Adjust as needed
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                            minHeight: 6,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Skip button - now with functionality
                      TextButton(
                        onPressed: () {
                          // Navigate to SetupDietsPage without animation
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => SetupDietsPage(
                                startProgressValue: 0.3, // Pass the current progress value
                              ),
                              transitionDuration: Duration.zero, // No animation
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Lewati',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Heading
                  Text(
                    'Apa kamu alergi terhadap sesuatu?',
                    style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 32),                  // Allergies grid
                  Expanded(
                    child: _isLoading 
                    ? Center(child: CircularProgressIndicator(color: primaryRed))
                    : allergensList.isEmpty
                      ? Center(child: Text('Tidak ada data alergi ditemukan'))
                      : GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: allergensList.map((allergen) {
                            final allergyName = allergen['name'] as String;
                            final isSelected = selectedAllergies.contains(allergyName);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedAllergies.remove(allergyName);
                                  } else {
                                    selectedAllergies.add(allergyName);
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryRed : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    allergyName,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  ),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,                      child: ElevatedButton(
                        onPressed: () async {
                          // Simpan alergi yang dipilih ke database jika user sudah login
                          try {
                            // Gunakan AuthService untuk mendapatkan ID user yang sedang login
                            final userId = AuthService.getCurrentUserId();
                            if (userId != null && selectedAllergies.isNotEmpty) {
                              // Dapatkan ID untuk semua alergi yang dipilih
                              final allergensData = await _supabase
                                  .from('allergens')
                                  .select('id, name')
                                  .filter('name', 'in', selectedAllergies.toList());
                                  
                              // Siapkan data untuk dimasukkan ke user_allergens
                              final userAllergens = allergensData.map((allergen) => {
                                'user_id': userId,
                                'allergen_id': allergen['id'],
                                'created_at': DateTime.now().toIso8601String(),
                              }).toList();
                                // Jika ada data, simpan ke database
                              if (userAllergens.isNotEmpty) {
                                await _supabase
                                  .from('user_allergens')
                                  .upsert(userAllergens);
                                  
                                print('Saved ${userAllergens.length} allergens for user $userId');
                              }
                            } else {
                              if (userId == null) {
                                print('Tidak ada user yang login');
                              } else if (selectedAllergies.isEmpty) {
                                print('Tidak ada alergi yang dipilih');
                              }
                            }
                          } catch (e) {
                            print('Error saving allergens: $e');
                            // Lanjutkan meski gagal menyimpan
                          }
                          
                          // Navigate to diets page with our selected allergies
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => SetupDietsPage(
                                startProgressValue: 0.3, // Pass the current progress value
                              ),
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Lanjut',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}