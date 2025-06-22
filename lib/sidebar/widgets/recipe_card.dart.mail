import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isSaved;
  final String cookTime;
  final VoidCallback onSaveTap;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.isSaved = false,
    required this.cookTime,
    required this.onSaveTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Recipe image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: const Icon(Icons.error, color: Colors.white),
                  );
                },
              ),
              
              // Dark gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Bookmark button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onSaveTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Cook time
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  // padding: const EdgeInsets.all(6),
                  // decoration: BoxDecoration(
                  //   color: Colors.white.withOpacity(0.2),
                  //   shape: BoxShape.circle,
                  // ),
                  // child: Row(
                  //   mainAxisSize: MainAxisSize.min,
                  //   children: [
                  //     // Icon(
                  //     //   Icons.access_time,
                  //     //   color: Colors.white,
                  //     //   size: 12,
                  //     // ),
                  //   ],
                  // ),
                ),
              ),
              
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cookTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              // Recipe title
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
