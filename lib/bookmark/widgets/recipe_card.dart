import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe_item.dart';

class RecipeCard extends StatelessWidget {
  final RecipeItem recipe;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const RecipeCard({
    Key? key,
    required this.recipe,
    this.showRemoveButton = false,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child:
                recipe.imageUrl.isNotEmpty &&
                        !recipe.imageUrl.startsWith('assets/')
                    ? Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/default_food.png',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                    : Image.asset(
                      recipe.imageUrl.isNotEmpty
                          ? recipe.imageUrl
                          : 'assets/images/default_food.png',
                      fit: BoxFit.cover,
                    ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          // Only show bookmark icon when NOT showing remove button
          if (!showRemoveButton)
            Positioned(
              top: 10,
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.bookmark,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          // Show remove button when in remove mode
          if (showRemoveButton && onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.likeCount} (${recipe.reviewCount} ulasan)',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${recipe.calories} Cal',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          '|',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                      Text(
                        '${recipe.prepTime} Porsi',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          '|',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                      Text(
                        '${recipe.cookTime} min',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
