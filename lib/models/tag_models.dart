// Defines the data models for tags (Allergens, Diet Programs, Equipment)

class Allergen {
  final int id;
  final String name;
  final String? description; // Optional, based on schema

  Allergen({
    required this.id,
    required this.name,
    this.description,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class DietProgram {
  final int id;
  final String name;
  final String? description; // Optional, based on schema

  DietProgram({
    required this.id,
    required this.name,
    this.description,
  });

  factory DietProgram.fromJson(Map<String, dynamic> json) {
    return DietProgram(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class Equipment {
  final int id;
  final String name;
  final String? description; // Optional, based on schema

  Equipment({
    required this.id,
    required this.name,
    this.description,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
