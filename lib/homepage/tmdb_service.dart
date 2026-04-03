import 'dart:convert';

import 'package:http/http.dart' as http;

class TmdbService {
  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = String.fromEnvironment('TMDB_API_KEY');
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _language = 'ru-RU';

  final http.Client _client;

  Future<List<TmdbMovie>> fetchPopularMovies() async {
    if (_apiKey.isEmpty) {
      throw const TmdbException(
        'TMDB API key не найден. Запустите приложение с --dart-define=TMDB_API_KEY=ваш_ключ',
      );
    }

    final genres = await _fetchGenres();

    final uri = Uri.parse(
      '$_baseUrl/movie/popular?api_key=$_apiKey&language=$_language&page=1',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw TmdbException('Ошибка загрузки фильмов: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? const []);

    return results
        .map((json) => TmdbMovie.fromJson(json as Map<String, dynamic>, genres))
        .where((movie) => movie.title.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<int, String>> _fetchGenres() async {
    final uri = Uri.parse(
      '$_baseUrl/genre/movie/list?api_key=$_apiKey&language=$_language',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw TmdbException('Ошибка загрузки жанров: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final genres = body['genres'] as List<dynamic>? ?? const [];

    final genreMap = <int, String>{};
    for (final item in genres) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as int?;
      final name = map['name'] as String?;
      if (id != null && name != null && name.isNotEmpty) {
        genreMap[id] = name;
      }
    }

    return genreMap;
  }
}

class TmdbMovie {
  TmdbMovie({
    required this.title,
    required this.posterUrl,
    required this.backdropUrl,
    required this.genreNames,
    required this.releaseDate,
    required this.voteAverage,
    required this.overview,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json, Map<int, String> genresMap) {
    final genreIds = (json['genre_ids'] as List<dynamic>? ?? const [])
        .map((id) => id as int)
        .toList(growable: false);

    final genreNames = genreIds
        .map((id) => genresMap[id])
        .whereType<String>()
        .toList(growable: false);

    return TmdbMovie(
      title: json['title'] as String? ?? '',
      posterUrl: _buildImageUrl(json['poster_path'] as String?),
      backdropUrl: _buildImageUrl(json['backdrop_path'] as String?),
      genreNames: genreNames,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      overview: json['overview'] as String? ?? '',
    );
  }

  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final List<String> genreNames;
  final String? releaseDate;
  final double voteAverage;
  final String overview;

  static String? _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }
    return 'https://image.tmdb.org/t/p/w780$path';
  }
}

class TmdbException implements Exception {
  const TmdbException(this.message);

  final String message;

  @override
  String toString() => message;
}
