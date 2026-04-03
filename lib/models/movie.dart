class MovieItem {
  final int id;
  final String title;
  final String imageUrl;
  final String category;
  final int year;
  final String duration;
  final double rating;
  final String description;

  const MovieItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.year,
    required this.duration,
    required this.rating,
    required this.description,
  });

  MovieItem copyWith({
    int? id,
    String? title,
    String? imageUrl,
    String? category,
    int? year,
    String? duration,
    double? rating,
    String? description,
  }) {
    return MovieItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      year: year ?? this.year,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      description: description ?? this.description,
    );
  }

  factory MovieItem.fromTmdbJson(
    Map<String, dynamic> json,
    Map<int, String> genresById,
  ) {
    final releaseDate = json['release_date'] as String?;
    final parsedYear = releaseDate != null && releaseDate.length >= 4
        ? int.tryParse(releaseDate.substring(0, 4)) ?? 0
        : 0;

    final genreIds = (json['genre_ids'] as List<dynamic>? ?? const [])
        .map((id) => id is int ? id : int.tryParse('$id'))
        .whereType<int>()
        .toList(growable: false);

    final primaryGenre = genreIds
        .map((id) => genresById[id])
        .whereType<String>()
        .firstWhere((_) => true, orElse: () => 'Без жанра');

    return MovieItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Без названия',
      imageUrl: _buildPosterUrl(json['poster_path'] as String?),
      category: primaryGenre,
      year: parsedYear,
      duration: '—',
      rating: ((json['vote_average'] as num?) ?? 0).toDouble(),
      description: json['overview'] as String? ?? 'Описание отсутствует',
    );
  }

  static String _buildPosterUrl(String? posterPath) {
    if (posterPath == null || posterPath.isEmpty) {
      return '';
    }
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }
}

class BannerItem {
  final String title;
  final String imageUrl;

  const BannerItem({required this.title, required this.imageUrl});
}
