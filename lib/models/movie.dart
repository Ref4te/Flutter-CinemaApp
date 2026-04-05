class MovieItem {
  static const _tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  final int id;
  final String title;
  final String imageUrl;
  final String category;
  final int year;
  final DateTime? releaseDate;
  final String duration;
  final double rating;
  final String description;

  const MovieItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.year,
    required this.releaseDate,
    required this.duration,
    required this.rating,
    required this.description,
  });

  factory MovieItem.fromTmdb(
    Map<String, dynamic> json, {
    required Map<int, String> genreMap,
  }) {
    final releaseDateRaw = (json['release_date'] as String?) ?? '';
    final releaseDate = DateTime.tryParse(releaseDateRaw);
    final year = int.tryParse(releaseDateRaw.split('-').first) ?? DateTime.now().year;
    final rating = ((json['vote_average'] ?? 0) as num).toDouble();
    final runtime = json['runtime'] as int?;

    String category = 'Без категории';
    final genres = json['genres'];
    if (genres is List && genres.isNotEmpty) {
      final genreName = genres.first['name'] as String?;
      if (genreName != null && genreName.isNotEmpty) {
        category = genreName;
      }
    } else {
      final genreIds = json['genre_ids'];
      if (genreIds is List && genreIds.isNotEmpty) {
        final genreId = genreIds.first as int;
        category = genreMap[genreId] ?? category;
      }
    }

    return MovieItem(
      id: json['id'] as int? ?? -1,
      title: (json['title'] as String?) ?? (json['name'] as String?) ?? 'Без названия',
      imageUrl: _posterUrl(json['poster_path'] as String?),
      category: category,
      year: year,
      releaseDate: releaseDate,
      duration: _formatDuration(runtime),
      rating: rating,
      description:
          (json['overview'] as String?)?.trim().isNotEmpty == true
          ? (json['overview'] as String).trim()
          : 'Описание пока недоступно.',
    );
  }

  static String _posterUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '$_tmdbImageBaseUrl$path';
  }

  static String _formatDuration(int? runtime) {
    if (runtime == null || runtime <= 0) return '—';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    if (hours == 0) return '${minutes}м';
    return '${hours}ч ${minutes}м';
  }
}

class BannerItem {
  static const _tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w780';

  final String title;
  final String imageUrl;

  const BannerItem({required this.title, required this.imageUrl});

  factory BannerItem.fromTmdb(Map<String, dynamic> json) {
    final backdropPath = json['backdrop_path'] as String?;
    return BannerItem(
      title: (json['title'] as String?) ?? (json['name'] as String?) ?? 'Без названия',
      imageUrl: backdropPath == null || backdropPath.isEmpty
          ? ''
          : '$_tmdbImageBaseUrl$backdropPath',
    );
  }
}
