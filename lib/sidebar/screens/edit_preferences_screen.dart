import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../models/allergen_model.dart';
import '../models/diet_program_model.dart';
import '../services/user_preferences_service.dart';
import '../services/supabase_service.dart';

class EditPreferencesScreen extends StatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  State<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen> {
  // Data states
  List<AllergenModel> _allAllergens = [];
  List<DietProgramModel> _allDietPrograms = [];
  Set<int> _selectedAllergenIds = {};
  Set<int> _selectedDietProgramIds = {};
  
  // UI states
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  
  // Search states
  String _allergenSearchQuery = '';
  String _dietProgramSearchQuery = '';
  final TextEditingController _allergenSearchController = TextEditingController();
  final TextEditingController _dietProgramSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _allergenSearchController.dispose();
    _dietProgramSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      // Load all data in parallel
      final results = await Future.wait([
        UserPreferencesService.getAllAllergens(),
        UserPreferencesService.getAllDietPrograms(),
        UserPreferencesService.getUserAllergens(userId),
        UserPreferencesService.getUserDietPrograms(userId),
      ]);

      _allAllergens = results[0] as List<AllergenModel>;
      _allDietPrograms = results[1] as List<DietProgramModel>;
      
      final userAllergens = results[2] as List<AllergenModel>;
      final userDietPrograms = results[3] as List<DietProgramModel>;

      // Set selected IDs
      _selectedAllergenIds = userAllergens.map((a) => a.id).toSet();
      _selectedDietProgramIds = userDietPrograms.map((d) => d.id).toSet();

    } catch (e) {
      _showErrorSnackBar('Gagal memuat data preferensi');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleAllergen(int allergenId) {
    setState(() {
      if (_selectedAllergenIds.contains(allergenId)) {
        _selectedAllergenIds.remove(allergenId);
      } else {
        _selectedAllergenIds.add(allergenId);
      }
      _hasChanges = true;
    });
  }

  void _toggleDietProgram(int dietProgramId) {
    setState(() {
      if (_selectedDietProgramIds.contains(dietProgramId)) {
        _selectedDietProgramIds.remove(dietProgramId);
      } else {
        _selectedDietProgramIds.add(dietProgramId);
      }
      _hasChanges = true;
    });
  }

  Future<void> _savePreferences() async {
    if (!_hasChanges) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        _showErrorSnackBar('User tidak ditemukan');
        return;
      }

      // Get current user preferences
      final currentAllergens = await UserPreferencesService.getUserAllergens(userId);
      final currentDietPrograms = await UserPreferencesService.getUserDietPrograms(userId);

      final currentAllergenIds = currentAllergens.map((a) => a.id).toSet();
      final currentDietProgramIds = currentDietPrograms.map((d) => d.id).toSet();

      // Calculate changes for allergens
      final allergensToAdd = _selectedAllergenIds.difference(currentAllergenIds);
      final allergensToRemove = currentAllergenIds.difference(_selectedAllergenIds);

      // Calculate changes for diet programs
      final dietProgramsToAdd = _selectedDietProgramIds.difference(currentDietProgramIds);
      final dietProgramsToRemove = currentDietProgramIds.difference(_selectedDietProgramIds);

      // Execute all changes
      final futures = <Future<bool>>[];

      // Add new allergens
      for (final allergenId in allergensToAdd) {
        futures.add(UserPreferencesService.addUserAllergen(userId, allergenId));
      }

      // Remove allergens
      for (final allergenId in allergensToRemove) {
        futures.add(UserPreferencesService.removeUserAllergen(userId, allergenId));
      }

      // Add new diet programs
      for (final dietProgramId in dietProgramsToAdd) {
        futures.add(UserPreferencesService.addUserDietProgram(userId, dietProgramId));
      }

      // Remove diet programs
      for (final dietProgramId in dietProgramsToRemove) {
        futures.add(UserPreferencesService.removeUserDietProgram(userId, dietProgramId));
      }

      // Wait for all operations to complete
      final results = await Future.wait(futures);
      
      // Check if all operations succeeded
      final allSucceeded = results.every((result) => result);

      if (allSucceeded) {
        _showSuccessSnackBar('Preferensi berhasil disimpan');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Beberapa perubahan gagal disimpan');
      }

    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan saat menyimpan');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<AllergenModel> get _filteredAllergens {
    if (_allergenSearchQuery.isEmpty) return _allAllergens;
    return _allAllergens.where((allergen) =>
        allergen.name.toLowerCase().contains(_allergenSearchQuery.toLowerCase())
    ).toList();
  }

  List<DietProgramModel> get _filteredDietPrograms {
    if (_dietProgramSearchQuery.isEmpty) return _allDietPrograms;
    return _allDietPrograms.where((program) =>
        program.name.toLowerCase().contains(_dietProgramSearchQuery.toLowerCase())
    ).toList();
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
                    _buildAllergensSection(),
                    const SizedBox(height: 32),
                    _buildDietProgramsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Edit Preferensi',
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

  Widget _buildAllergensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Alergen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedAllergenIds.length} dipilih',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih alergen yang Anda miliki untuk mendapatkan rekomendasi resep yang aman.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        _buildSearchField(
          controller: _allergenSearchController,
          hintText: 'Cari alergen...',
          onChanged: (value) {
            setState(() {
              _allergenSearchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildAllergensList(),
      ],
    );
  }

  Widget _buildDietProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_dining,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Program Diet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedDietProgramIds.length} dipilih',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih program diet yang Anda jalani untuk mendapatkan resep yang sesuai.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        _buildSearchField(
          controller: _dietProgramSearchController,
          hintText: 'Cari program diet...',
          onChanged: (value) {
            setState(() {
              _dietProgramSearchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDietProgramsList(),
      ],
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: AppColors.grayLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildAllergensList() {
    final filteredAllergens = _filteredAllergens;
    
    if (filteredAllergens.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            _allergenSearchQuery.isEmpty 
                ? 'Tidak ada alergen tersedia'
                : 'Tidak ada alergen yang cocok dengan pencarian',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: filteredAllergens.map((allergen) {
        final isSelected = _selectedAllergenIds.contains(allergen.id);
        return _buildPreferenceItem(
          title: allergen.name,
          description: allergen.description,
          isSelected: isSelected,
          color: Colors.red,
          onTap: () => _toggleAllergen(allergen.id),
        );
      }).toList(),
    );
  }

  Widget _buildDietProgramsList() {
    final filteredDietPrograms = _filteredDietPrograms;
    
    if (filteredDietPrograms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            _dietProgramSearchQuery.isEmpty 
                ? 'Tidak ada program diet tersedia'
                : 'Tidak ada program diet yang cocok dengan pencarian',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: filteredDietPrograms.map((program) {
        final isSelected = _selectedDietProgramIds.contains(program.id);
        return _buildPreferenceItem(
          title: program.name,
          description: program.description,
          isSelected: isSelected,
          color: Colors.green,
          onTap: () => _toggleDietProgram(program.id),
        );
      }).toList(),
    );
  }

  Widget _buildPreferenceItem({
    required String title,
    String? description,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected ? color : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : Colors.black,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _savePreferences,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
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
              : Text(
                  _hasChanges ? 'Simpan Perubahan' : 'Kembali',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
