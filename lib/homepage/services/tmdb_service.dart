import 'dart:convert';
import 'dart:io';

import '../../models/movie.dart';

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _apiKey = String.fromEnvironment('TMDB_API_KEY');

  Future<List<MovieItem>> fetchPopularMovies({int page = 1}) async {
    _ensureApiKey();

    final genres = await _fetchGenres();
    final uri = Uri.parse(
      '$_baseUrl/movie/popular?api_key=$_apiKey&language=ru-RU&page=$page',
    );

    final response = await _getJson(uri);
    final results = response['results'] as List<dynamic>? ?? const [];

    return results
        .whereType<Map<String, dynamic>>()
        .map((json) => MovieItem.fromTmdbJson(json, genres))
        .toList(growable: false);
  }

  Future<MovieItem> fetchMovieDetails(MovieItem movie) async {
    _ensureApiKey();

    final uri = Uri.parse(
      '$_baseUrl/movie/${movie.id}?api_key=$_apiKey&language=ru-RU',
    );

    final json = await _getJson(uri);
    final runtime = (json['runtime'] as num?)?.toInt();
    final genres = (json['genres'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((genre) => genre['name'] as String?)
        .whereType<String>()
        .toList(growable: false);

    return movie.copyWith(
      category: genres.isNotEmpty ? genres.first : movie.category,
      duration: _formatDuration(runtime),
      description: (json['overview'] as String?)?.isNotEmpty == true
          ? json['overview'] as String
          : movie.description,
    );
  }

  Future<Map<int, String>> _fetchGenres() async {
    final uri = Uri.parse(
      '$_baseUrl/genre/movie/list?api_key=$_apiKey&language=ru-RU',
    );
    final json = await _getJson(uri);

    final genres = json['genres'] as List<dynamic>? ?? const [];
    return {
      for (final genre in genres.whereType<Map<String, dynamic>>())
        if (genre['id'] is int && genre['name'] is String)
          genre['id'] as int: genre['name'] as String,
    };
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set('accept', 'application/json');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode >= 400) {
        throw Exception('TMDb API error ${response.statusCode}: $body');
      }

      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  String _formatDuration(int? runtime) {
    if (runtime == null || runtime <= 0) {
      return '—';
    }
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    if (hours == 0) {
      return '${minutes}м';
    }
    return '${hours}ч ${minutes}м';
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'TMDB_API_KEY не задан. Запустите приложение с --dart-define=TMDB_API_KEY=... ',
      );
    }
  }
}
