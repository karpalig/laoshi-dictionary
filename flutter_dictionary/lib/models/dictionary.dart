class Dictionary {
  final String id;
  String name;
  String? description;
  bool isActive;
  DateTime createdAt;
  String color;

  Dictionary({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.color = 'cyan',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
    };
  }

  factory Dictionary.fromMap(Map<String, dynamic> map) {
    return Dictionary(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      color: map['color'] as String? ?? 'cyan',
    );
  }

  Dictionary copyWith({
    String? name,
    String? description,
    bool? isActive,
    String? color,
  }) {
    return Dictionary(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      color: color ?? this.color,
    );
  }
}
