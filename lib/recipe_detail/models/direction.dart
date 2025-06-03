class Direction {
  final int order;
  final String description;
  final String? imageUrl;
  bool isCompleted;

  Direction({
    required this.order,
    required this.description,
    this.imageUrl,
    this.isCompleted = false,
  });
}