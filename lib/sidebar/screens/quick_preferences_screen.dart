import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/preference_selection_chip.dart';
import '../models/allergen_model.dart';
import '../models/diet_program_model.dart';
import '../services/user_preferences_service.dart';
import '../services/supabase_service.dart';
import 'edit_preferences_screen.dart';

class QuickPreferencesScreen extends StatefulWidget {
  const QuickPreferencesScreen({super.key});

  @override
  State<QuickPreferencesScreen> createState() => _QuickPreferencesScreenState();
}

class _QuickPreferencesScreenState extends State<QuickPreferencesScreen> {
  List<AllergenModel> _popularAllergens = [];
  List<DietProgramModel> _popularDietPrograms = [];
  Set<int> _selectedAllergenIds = {};
  Set<int> _selectedDietProgramIds = {};
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPopularPreferences();
  }

  Future<void> _loadPopularPreferences() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      // Load popular allergens and diet programs (first 10 of each)
      final results = await Future.wait([
        UserPreferencesService.getAllAllergens(),
        UserPreferencesService.getAllDietPrograms(),
        UserPreferencesService.getUserAllergens(userId),
        UserPreferencesService.getUserDietPrograms(userId),
      ]);

      final allAllergens = results[0] as List<AllergenModel>;
      final allDietPrograms = results[1] as List<DietProgramModel>;
      final userAllergens = results[2] as List<AllergenModel>;
      final userDietPrograms = results[3] as List<DietProgramModel>;

      // Take first 10 as "popular" (you can modify this logic)
      _popularAllergens = allAllergens.take(10).toList();
      _popularDietPrograms = allDietPrograms.take(8).toList();

      // Set current selections
      _selectedAllergenIds = userAllergens.map((a) => a.id).toSet();
      _selectedDietProgramIds = userDietPrograms.map((d) => d.id).toSet();

    } catch (e) {
      print('Error loading popular preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      // Get current preferences
      final currentAllergens = await UserPreferencesService.getUserAllergens(userId);
      final currentDietPrograms = await UserPreferencesService.getUserDietPrograms(userId);

      final currentAllergenIds = currentAllergens.map((a) => a.id).toSet();
      final currentDietProgramIds = currentDietPrograms.map((d) => d.id).toSet();

      // Calculate changes
      final allergensToAdd = _selectedAllergenIds.difference(currentAllergenIds);
      final allergensToRemove = currentAllergenIds.difference(_selectedAllergenIds);
      final dietProgramsToAdd = _selectedDietProgramIds.difference(currentDietProgramIds);
      final dietProgramsToRemove = currentDietProgramIds.difference(_selectedDietProgramIds);

      // Execute changes
      final futures = <Future<bool>>[];

      for (final id in allergensToAdd) {
        futures.add(UserPreferencesService.addUserAllergen(userId, id));
      }
      for (final id in allergensToRemove) {
        futures.add(UserPreferencesService.removeUserAllergen(userId, id));
      }
      for (final id in dietProgramsToAdd) {
        futures.add(UserPreferencesService.addUserDietProgram(userId, id));
      }
      for (final id in dietProgramsToRemove) {
        futures.add(UserPreferencesService.removeUserDietProgram(userId, id));
      }

      await Future.wait(futures);
      
      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan preferensi'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroSection(),
                    const SizedBox(height: 32),
                    _buildAllergensSection(),
                    const SizedBox(height: 32),
                    _buildDietProgramsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Preferensi Cepat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildIntroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atur Preferensi Makanan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih alergen dan program diet Anda untuk mendapatkan rekomendasi resep yang lebih personal.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAllergensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Alergen Umum',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih alergen yang Anda miliki',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          children: _popularAllergens.map((allergen) {
            return PreferenceSelectionChip(
              label: allergen.name,
              isSelected: _selectedAllergenIds.contains(allergen.id),
              color: Colors.red,
              icon: Icons.warning_rounded,
              onTap: () {
                setState(() {
                  if (_selectedAllergenIds.contains(allergen.id)) {
                    _selectedAllergenIds.remove(allergen.id);
                  } else {
                    _selectedAllergenIds.add(allergen.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDietProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_dining,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Program Diet Populer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih program diet yang Anda jalani',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          children: _popularDietPrograms.map((program) {
            return PreferenceSelectionChip(
              label: program.name,
              isSelected: _selectedDietProgramIds.contains(program.id),
              color: Colors.green,
              icon: Icons.local_dining,
              onTap: () {
                setState(() {
                  if (_selectedDietProgramIds.contains(program.id)) {
                    _selectedDietProgramIds.remove(program.id);
                  } else {
                    _selectedDietProgramIds.add(program.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan & Lanjutkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditPreferencesScreen(),
                ),
              );
            },
            child: const Text(
              'Lihat Semua Opsi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
