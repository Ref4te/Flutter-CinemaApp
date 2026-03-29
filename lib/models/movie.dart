class MovieItem {
  final String title;
  final String imageUrl;
  final String category;
  final int year;
  final String duration;
  final double rating;
  final String description;

  const MovieItem({
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.year,
    required this.duration,
    required this.rating,
    required this.description,
  });

  // Заглушка для будущего API
  factory MovieItem.fromJson(Map<String, dynamic> json) {
    return MovieItem(
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      year: json['year'] ?? 2024,
      duration: json['duration'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
    );
  }
}

class BannerItem {
  final String title;
  final String imageUrl;

  const BannerItem({required this.title, required this.imageUrl});
}