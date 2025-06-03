class Ingredient {
  final int order;
  final String name;
  final String amount;
  final String unit;
  bool isChecked;

  Ingredient({
    required this.order,
    required this.name,
    required this.amount,
    required this.unit,
    this.isChecked = false,
  });
}