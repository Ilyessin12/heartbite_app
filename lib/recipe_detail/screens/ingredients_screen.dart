import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../widgets/recipe_header.dart';
import '../widgets/ingredient_item.dart';
import '../utils/constants.dart';
import 'directions_screen.dart';

class IngredientsScreen extends StatefulWidget {
  final Recipe recipe;
  
  const IngredientsScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 72), // Space for back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RecipeHeader(
                          recipe: widget.recipe,
                          showAuthor: false,
                        ),
                        const SizedBox(height: 24),
                        
                        const Text(
                          "Bahan-bahan",
                          style: AppTextStyles.subheading,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Siapkan bahan-bahan sebelum mulai memasak",
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 16),
                        
                        // Ingredients list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: widget.recipe.ingredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = widget.recipe.ingredients[index];
                            return IngredientItem(
                              ingredient: ingredient,
                              showCheckbox: true,
                              onChecked: (checked) {
                                setState(() {
                                  ingredient.isChecked = checked;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 80), // Space for button
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Back button - fixed at top
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Next button - fixed at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DirectionsScreen(recipe: widget.recipe),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Selanjutnya",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}