import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../utils/constants.dart';

class IngredientItem extends StatelessWidget {
  final Ingredient ingredient;
  final Function(bool)? onChecked;
  final bool showCheckbox;
  
  const IngredientItem({
    super.key,
    required this.ingredient,
    this.onChecked,
    this.showCheckbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              (ingredient.order + 1).toString(), // Add 1 to display order starting from 1
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                ingredient.name,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              "${ingredient.amount} ${ingredient.unit}",
              style: AppTextStyles.caption,
            ),
            if (showCheckbox && onChecked != null) ...[
              const SizedBox(width: 8),
              Checkbox(
                value: ingredient.isChecked,
                onChanged: (value) => onChecked!(value ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}