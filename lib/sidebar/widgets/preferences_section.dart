import 'package:flutter/material.dart';
import '../models/allergen_model.dart';
import '../models/diet_program_model.dart';
import '../widgets/preference_chip.dart';
import '../theme/app_theme.dart';

class PreferencesSection extends StatelessWidget {
  final List<AllergenModel> allergens;
  final List<DietProgramModel> dietPrograms;
  final bool isCurrentUser;
  final VoidCallback? onEditTap;

  const PreferencesSection({
    super.key,
    required this.allergens,
    required this.dietPrograms,
    this.isCurrentUser = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show section if no preferences and not current user
    if (allergens.isEmpty && dietPrograms.isEmpty && !isCurrentUser) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preferensi Makanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCurrentUser && onEditTap != null)
                GestureDetector(
                  onTap: onEditTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          
          if (allergens.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Alergen',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              children: allergens.map((allergen) {
                return PreferenceChip(
                  label: allergen.name,
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                );
              }).toList(),
            ),
          ],
          
          if (dietPrograms.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Program Diet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              children: dietPrograms.map((program) {
                return PreferenceChip(
                  label: program.name,
                  icon: Icons.local_dining,
                  color: Colors.green,
                );
              }).toList(),
            ),
          ],
          
          if (allergens.isEmpty && dietPrograms.isEmpty && isCurrentUser) ...[
            const SizedBox(height: 8),
            Text(
              'Belum ada preferensi makanan. Tap edit untuk menambahkan alergen dan program diet.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
