import 'package:intl/intl.dart';

import 'cocktail_model.dart';

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.userId,
    required this.cocktailId,
    required this.name,
    this.imageUrl,
    required this.eventDate,
    required this.rating,
    required this.comment,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, userId, cocktailId, name, comment;
  final String? imageUrl;
  final DateTime eventDate;
  final int rating, createdAt, updatedAt;
  final double? latitude, longitude;
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'cocktailId': cocktailId,
    'name': name,
    'imageUrl': imageUrl,
    'eventDate': DateFormat('yyyy-MM-dd').format(eventDate),
    'rating': rating,
    'comment': comment,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
  factory DiaryEntry.fromMap(Map<String, dynamic> m) => DiaryEntry(
    id: m['id'] as String,
    userId: m['userId'] as String,
    cocktailId: m['cocktailId'] as String? ?? '',
    name: m['name'] as String,
    imageUrl: m['imageUrl'] as String?,
    eventDate: DateTime.parse(m['eventDate'] as String),
    rating: (m['rating'] as num).toInt(),
    comment: m['comment'] as String? ?? '',
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    createdAt: (m['createdAt'] as num).toInt(),
    updatedAt: (m['updatedAt'] as num).toInt(),
  );
  Cocktail get cocktail =>
      Cocktail(id: cocktailId, name: name, thumb: imageUrl);
}
