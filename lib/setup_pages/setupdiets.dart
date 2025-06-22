import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'setupaccount.dart'; // Import SetupAccountPage
import 'setupallergies.dart'; // Import SetupAllergiesPage
import '../services/supabase_client.dart'; // Import Supabase client

class SetupDietsPage extends StatefulWidget {
  // Add parameter for the starting progress value
  final double startProgressValue;
  
  const SetupDietsPage({
    Key? key, 
    this.startProgressValue = 0.3, // Default to 0.3 if not provided
  }) : super(key: key);

  @override
  State<SetupDietsPage> createState() => _SetupDietsPageState();
}

class _SetupDietsPageState extends State<SetupDietsPage> with SingleTickerProviderStateMixin {
  final Color primaryRed = const Color(0xFF8E1616);
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  final _supabase = SupabaseClientWrapper().client;
  
  // Track selected diets
  final Set<String> selectedDiets = {};
  
  // List untuk menyimpan data diet dari database
  List<Map<String, dynamic>> dietProgramsList = [];
  bool _isLoading = true;
  bool _fetchFailed = false; // Tambahkan flag untuk tracking fetch failure
  @override
  void initState() {
    super.initState();
    // Set up animation controller for the progress bar
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: widget.startProgressValue,
      end: 0.6, // Target progress value for this page
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      )
    );
    
    // Start the animation when the widget is built
    _progressController.forward();
    
    // Fetch diet programs from database
    fetchDietPrograms();
  }
  
  // Fungsi untuk mengambil data diet dari Supabase
  Future<void> fetchDietPrograms() async {
    setState(() {
      _isLoading = true;
    });
      try {
      // Ambil data dari tabel diet_programs, hanya nama yang kita perlukan
      final response = await _supabase
          .from('diet_programs')
          .select('name')
          .order('name');
      
      // Update state dengan data yang diterima
      if (!mounted) return;
      setState(() {
        dietProgramsList = List<Map<String, dynamic>>.from(response);
      });
      
      // Cek apakah user sudah login dan ambil diet yang sudah dipilih
      await loadSelectedDiets();
    } catch (e) {
      print('Error fetching diet programs: $e');
      // Set empty list and let the UI show error message
      if (!mounted) return;
      setState(() {
        dietProgramsList = []; // Empty list instead of static data
        _fetchFailed = true;   // Set flag to show fetch failed message
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Fungsi untuk memuat diet yang sudah dipilih oleh user
  Future<void> loadSelectedDiets() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        // Ambil diet yang sudah dipilih user dari tabel user_diet_programs
        final userDietsResponse = await _supabase
            .from('user_diet_programs')
            .select('diet_programs(name)')
            .eq('user_id', userId);
        
        if (userDietsResponse.isNotEmpty) {
          final selectedNames = userDietsResponse
              .map((item) => item['diet_programs']['name'] as String)
              .toSet();
          
          setState(() {
            selectedDiets.addAll(selectedNames);
          });
          print('Loaded ${selectedNames.length} previously selected diets');
        }
      }
    } catch (e) {
      print('Error loading selected diets: $e');
      // Jika gagal, tidak masalah, user bisa pilih lagi
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // Function to navigate back to allergies page
  void _navigateBackToAllergies() {
    // Navigate to SetupAllergiesPage without animation
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const SetupAllergiesPage(),
        transitionDuration: Duration.zero, // No animation
        reverseTransitionDuration: Duration.zero,
      ),
    );
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
              'assets/images/Ornament.png',
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
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
                      // Back arrow in red circle - Now with updated navigation
                      GestureDetector(
                        onTap: _navigateBackToAllergies, // Use the new navigation function
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

                      const SizedBox(width: 16),

                      // Animated progress indicator
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progressAnimation.value,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                                minHeight: 6,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Skip button
                      TextButton(
                        onPressed: () {
                          // Navigate to SetupAccountPage without animation
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => SetupAccountPage(
                                startProgressValue: _progressAnimation.value,
                              ),
                              transitionDuration: Duration.zero,
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
                    'Ada pola makan\ntertentu yang kamu ikuti?',
                    style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 32),                  // Diets wrap
                  Expanded(
                    child: _isLoading 
                    ? Center(child: CircularProgressIndicator(color: primaryRed))
                    : _fetchFailed
                      ? Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal mengambil data',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: fetchDietPrograms,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryRed,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ))
                      : dietProgramsList.isEmpty
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada data diet ditemukan',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ))
                        : Wrap(
                          spacing: 12, // Jarak horizontal antar box
                          runSpacing: 12, // Jarak vertikal antar baris
                          alignment: WrapAlignment.start, // Rata kiri seperti grid sebelumnya
                          children: dietProgramsList.map((dietProgram) {
                            final dietName = dietProgram['name'] as String;
                            final isSelected = selectedDiets.contains(dietName);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedDiets.remove(dietName);
                                  } else {
                                    selectedDiets.add(dietName);
                                  }
                                });
                              },
                              child: IntrinsicWidth(
                                child: Container(
                                  height: 40, // Tinggi seragam untuk semua box
                                  padding: const EdgeInsets.symmetric(horizontal: 16), // Padding dalam box
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
                                      dietName,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.white : Colors.black,
                                      ),
                                    ),
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
                      height: 56,
                      child: ElevatedButton(                        onPressed: () async {
                          // Simpan diet yang dipilih ke database jika user sudah login
                          try {
                            final userId = _supabase.auth.currentUser?.id;
                            if (userId != null && selectedDiets.isNotEmpty) {
                              // Dapatkan ID untuk semua diet yang dipilih
                              final dietProgramsData = await _supabase
                                  .from('diet_programs')
                                  .select('id, name')
                                  .filter('name', 'in', selectedDiets.toList());
                                  
                              // Siapkan data untuk dimasukkan ke user_diet_programs
                              final userDietPrograms = dietProgramsData.map((dietProgram) => {
                                'user_id': userId,
                                'diet_program_id': dietProgram['id'],
                              }).toList();
                              
                              // Jika ada data, simpan ke database
                              if (userDietPrograms.isNotEmpty) {
                                await _supabase
                                  .from('user_diet_programs')
                                  .upsert(userDietPrograms);
                              }
                              
                              print('Saved ${userDietPrograms.length} diet programs for user');
                            }
                          } catch (e) {
                            print('Error saving diet programs: $e');
                            // Lanjutkan meski gagal menyimpan
                          }
                          
                          // Navigate to SetupAccountPage with animation
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => SetupAccountPage(
                                startProgressValue: _progressAnimation.value, // Pass current progress value
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