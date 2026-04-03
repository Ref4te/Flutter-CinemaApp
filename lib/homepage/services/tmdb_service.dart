import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/movie.dart';

class TmdbService {
  static const String _apiHost = 'api.themoviedb.org';
  static const String _apiVersion = '3';
  static const String _language = 'ru-RU';

  final String apiKey;

  const TmdbService({required this.apiKey});

  Future<List<MovieItem>> fetchPopularMovies() async {
    final genreById = await _fetchGenres();

    final response = await http.get(
      Uri.https(_apiHost, '/$_apiVersion/movie/popular', {
        'api_key': apiKey,
        'language': _language,
        'page': '1',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки фильмов: ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (payload['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((movieJson) => MovieItem.fromTmdb(json: movieJson, genreById: genreById))
        .toList(growable: false);

    return results;
  }

  Future<Map<int, String>> _fetchGenres() async {
    final response = await http.get(
      Uri.https(_apiHost, '/$_apiVersion/genre/movie/list', {
        'api_key': apiKey,
        'language': _language,
      }),
    );

    if (response.statusCode != 200) {
      return const {};
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final genres = (payload['genres'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    return {
      for (final genre in genres)
        if (genre['id'] is int && genre['name'] is String) genre['id'] as int: genre['name'] as String,
    };
  }
}
