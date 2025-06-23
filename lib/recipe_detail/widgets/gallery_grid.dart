import 'package:flutter/material.dart';

class GalleryGrid extends StatelessWidget {
  final List<String> images;
  final Function(int) onImageTap;
  final int crossAxisCount;
  final bool showAll;

  const GalleryGrid({
    super.key,
    required this.images,
    required this.onImageTap,
    this.crossAxisCount = 3,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayImages = showAll ? images : images.take(4).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount:
          showAll ? displayImages.length : Math.min(4, displayImages.length),
      itemBuilder: (context, index) {
        if (!showAll && index == 3 && images.length > 4) {
          // Show the "more" overlay on the last image
          return GestureDetector(
            onTap: () => onImageTap(index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      displayImages[index].isNotEmpty
                          ? Image.network(
                            displayImages[index],
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Image.asset(
                                  'assets/images/default_food.png',
                                  fit: BoxFit.cover,
                                ),
                          )
                          : Image.asset(
                            'assets/images/default_food.png',
                            fit: BoxFit.cover,
                          ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "+${images.length - 4}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return GestureDetector(
          onTap: () => onImageTap(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                displayImages[index].isNotEmpty
                    ? Image.network(
                      displayImages[index],
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Image.asset(
                            'assets/images/default_food.png',
                            fit: BoxFit.cover,
                          ),
                    )
                    : Image.asset(
                      'assets/images/default_food.png',
                      fit: BoxFit.cover,
                    ),
          ),
        );
      },
    );
  }
}

// Helper class to use min function
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
