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

  factory MovieItem.fromTmdb({
    required Map<String, dynamic> json,
    required Map<int, String> genreById,
  }) {
    final releaseDate = (json['release_date'] as String?) ?? '';
    final parsedYear = releaseDate.length >= 4 ? int.tryParse(releaseDate.substring(0, 4)) : null;

    final genreIdsRaw = (json['genre_ids'] as List<dynamic>?) ?? const [];
    final genres = genreIdsRaw
        .whereType<int>()
        .map((id) => genreById[id])
        .whereType<String>()
        .toList(growable: false);

    final posterPath = json['poster_path'] as String?;

    return MovieItem(
      id: json['id'] as int? ?? 0,
      title: (json['title'] as String?) ?? (json['name'] as String?) ?? 'Без названия',
      imageUrl: posterPath == null || posterPath.isEmpty
          ? ''
          : 'https://image.tmdb.org/t/p/w500$posterPath',
      category: genres.isNotEmpty ? genres.first : 'Без категории',
      year: parsedYear ?? 0,
      duration: '—',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      description: (json['overview'] as String?)?.trim().isNotEmpty == true
          ? (json['overview'] as String)
          : 'Описание отсутствует.',
    );
  }
}

class BannerItem {
  final String title;
  final String imageUrl;

  const BannerItem({required this.title, required this.imageUrl});

  factory BannerItem.fromMovie(MovieItem movie) {
    return BannerItem(title: movie.title, imageUrl: movie.imageUrl);
  }
}
