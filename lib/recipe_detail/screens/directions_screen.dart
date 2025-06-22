import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/direction.dart';
import '../widgets/recipe_header.dart';
import '../widgets/direction_item.dart';
import '../utils/constants.dart';

class DirectionsScreen extends StatefulWidget {
  final Recipe recipe;

  const DirectionsScreen({super.key, required this.recipe});

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
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
                        RecipeHeader(recipe: widget.recipe, showAuthor: false),
                        const SizedBox(height: 24),

                        // Directions section header
                        const Text(
                          "Langkah-langkah",
                          style: AppTextStyles.subheading,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Ikuti langkah-langkah ini untuk memasak resep ini",
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 16),

                        // Directions list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: widget.recipe.directions.length,
                          itemBuilder: (context, index) {
                            final direction = widget.recipe.directions[index];
                            return DirectionItem(
                              direction: direction,
                              showCheckbox: true,
                              onChecked: (checked) {
                                setState(() {
                                  direction.isCompleted = checked;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 80), // Space for finish button
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
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),

            // Finish button - fixed at bottom
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
                    onPressed: () => _showCompletionDialog(context),
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
                          "Selesai",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check, size: 16, color: Colors.white),
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

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Selamat!"),
            content: const Text(
              "Anda telah berhasil menyelesaikan resep ini. Apakah Anda ingin berbagi pengalaman Anda?",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    ModalRoute.withName('/'),
                  ); // Go back to home screen
                },
                child: const Text("Nanti Saja"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    ModalRoute.withName('/'),
                  ); // Go back to home screen
                  // Show share options or comment section
                },
                child: const Text("Bagikan"),
              ),
            ],
          ),
    );
  }
}
