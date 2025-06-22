import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../utils/constants.dart';

class RecipeHeader extends StatelessWidget {
  final Recipe recipe;
  final bool showAuthor;
  final bool showOverlayInfo;
  final int likeCount;
  final bool isFavorite;
  
  const RecipeHeader({
    super.key,
    required this.recipe,
    this.showAuthor = true,
    this.showOverlayInfo = true,
    required this.likeCount, // Added
    required this.isFavorite, // Added
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAuthor) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Author info on the left
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage(
                      "assets/images/avatars/avatar1.jpg",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${recipe.authorRecipeCount} Recipes",
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Rating on the right
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      recipe.rating.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: recipe.imageUrl.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/cookbooks/placeholder_image.jpg', // Placeholder image
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/cookbooks/placeholder_image.jpg', // Placeholder for empty URL
                      width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            if (showOverlayInfo) ...[
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white, // Use white for border if not favorited for visibility on dark overlay
                            size: 18, // Slightly larger for prominence
                          ),
                          const SizedBox(width: 6),
                          Text(
                            likeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // Ensure visibility
                            ),
                          ),
                           // Removed "reviews" text or can be changed to "likes"
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}