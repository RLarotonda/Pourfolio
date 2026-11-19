class DrinkCollection {
  const DrinkCollection({
    required this.id,
    required this.userId,
    required this.name,
    required this.drinks,
    required this.createdAt,
  });
  final String id, userId, name;
  final Map<String, Map<String, dynamic>> drinks;
  final int createdAt;
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'drinks': drinks,
    'createdAt': createdAt,
  };
  factory DrinkCollection.fromMap(Map<String, dynamic> m) => DrinkCollection(
    id: m['id'] as String,
    userId: m['userId'] as String,
    name: m['name'] as String,
    createdAt: (m['createdAt'] as num).toInt(),
    drinks: (m['drinks'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
    ),
  );
}
