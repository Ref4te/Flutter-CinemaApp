import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

class TmdbData {
  final List<BannerItem> banners;
  final List<MovieItem> movies;

  const TmdbData({required this.banners, required this.movies});
}

class TmdbService {
  static const String _apiBaseUrl = 'https://api.themoviedb.org/3';
  static const String _apiKey = String.fromEnvironment('TMDB_API_KEY');
  static const String _language = 'ru-RU';

  Future<TmdbData> loadHomeData() async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'TMDb API key не найден. Передайте ключ через --dart-define=TMDB_API_KEY=... ',
      );
    }

    final genreMap = await _loadGenres();
    final popularResponse = await _getJson('/movie/popular');
    final trendingResponse = await _getJson('/trending/movie/week');

    final rawMovies = (popularResponse['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final rawBanners = (trendingResponse['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final movies = rawMovies
        .where((movie) => (movie['poster_path'] as String?)?.isNotEmpty == true)
        .take(20)
        .map((movie) => MovieItem.fromTmdb(movie, genreMap: genreMap))
        .toList(growable: false);

    final banners = rawBanners
        .where((movie) => (movie['backdrop_path'] as String?)?.isNotEmpty == true)
        .take(5)
        .map(BannerItem.fromTmdb)
        .toList(growable: false);

    return TmdbData(banners: banners, movies: movies);
  }

  Future<Map<int, String>> _loadGenres() async {
    final json = await _getJson('/genre/movie/list');
    final genres = (json['genres'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return {
      for (final genre in genres)
        if (genre['id'] is int && genre['name'] is String)
          genre['id'] as int: genre['name'] as String,
    };
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final uri = Uri.parse(
      '$_apiBaseUrl$path?api_key=$_apiKey&language=$_language&page=1',
    );
    final response = await http.get(uri);

    if (response.statusCode >= 400) {
      throw Exception('TMDb вернул ошибку ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
