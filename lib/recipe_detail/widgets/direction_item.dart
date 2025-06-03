import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../utils/constants.dart';

class DirectionItem extends StatelessWidget {
  final Direction direction;
  final Function(bool)? onChecked;
  final bool showCheckbox;
  
  const DirectionItem({
    super.key,
    required this.direction,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              direction.order.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    direction.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  if (direction.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          direction.imageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showCheckbox && onChecked != null) ...[
              Checkbox(
                value: direction.isCompleted,
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