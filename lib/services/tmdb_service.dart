import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/movie.dart';

class TmdbData {
  final List<BannerItem> banners;
  final List<MovieItem> movies;

  const TmdbData({required this.banners, required this.movies});
}

class MovieDetailsData {
  final List<String> genres;
  final int runtimeMinutes;

  const MovieDetailsData({
    required this.genres,
    required this.runtimeMinutes,
  });
}

class MovieCastMember {
  static const _tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w185';

  final String name;
  final String? character;
  final String? profileImageUrl;

  const MovieCastMember({
    required this.name,
    this.character,
    this.profileImageUrl,
  });

  factory MovieCastMember.fromTmdb(Map<String, dynamic> json) {
    final profilePath = json['profile_path'] as String?;
    return MovieCastMember(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Неизвестный актер',
      character: (json['character'] as String?)?.trim(),
      profileImageUrl: profilePath == null || profilePath.isEmpty
          ? null
          : '$_tmdbImageBaseUrl$profilePath',
    );
  }
}

class MovieReviewData {
  final String author;
  final String content;
  final DateTime? createdAt;
  final double? rating;

  const MovieReviewData({
    required this.author,
    required this.content,
    this.createdAt,
    this.rating,
  });
}

class MovieFullDetailsData {
  final List<String> genres;
  final int runtimeMinutes;
  final String overview;
  final String? trailerYoutubeId;
  final String? director;
  final List<String> countries;
  final List<MovieCastMember> cast;
  final List<MovieReviewData> reviews;
  final double voteAverage;
  final int voteCount;
  final String? ageRating;
  final String? tagline;
  final String? originalTitle;
  final String? status;
  final DateTime? releaseDate;

  const MovieFullDetailsData({
    required this.genres,
    required this.runtimeMinutes,
    required this.overview,
    required this.trailerYoutubeId,
    required this.director,
    required this.countries,
    required this.cast,
    required this.reviews,
    required this.voteAverage,
    required this.voteCount,
    required this.ageRating,
    required this.tagline,
    required this.originalTitle,
    required this.status,
    required this.releaseDate,
  });
}

class TmdbService {
  static const String _apiBaseUrl = 'https://api.themoviedb.org/3';
  static String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';
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

  Future<MovieDetailsData> loadMovieDetails(int movieId) async {
    final json = await _getJson('/movie/$movieId');
    final genresJson = (json['genres'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final runtime = (json['runtime'] as num?)?.toInt() ?? 0;
    final genres = genresJson
        .map((genre) => genre['name'] as String?)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim())
        .toList(growable: false);

    return MovieDetailsData(genres: genres, runtimeMinutes: runtime);
  }

  Future<MovieFullDetailsData> loadMovieFullDetails(int movieId) async {
    final json = await _getJson(
      '/movie/$movieId',
      extraQuery: '&append_to_response=videos,credits,reviews,release_dates',
    );
    final genresJson = (json['genres'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final runtime = (json['runtime'] as num?)?.toInt() ?? 0;
    final genres = genresJson
        .map((genre) => genre['name'] as String?)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim())
        .toList(growable: false);

    final overview = (json['overview'] as String?)?.trim() ?? '';
    final credits = json['credits'] as Map<String, dynamic>? ?? const {};
    final crew = (credits['crew'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final castJson = (credits['cast'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final productionCountries = (json['production_countries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final reviewsJson = ((json['reviews'] as Map<String, dynamic>?)?['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final videos = ((json['videos'] as Map<String, dynamic>?)?['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final trailerYoutubeId = _extractTrailerYoutubeId(videos);
    String? director;
    for (final member in crew) {
      if (member['job'] == 'Director') {
        final name = (member['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          director = name;
          break;
        }
      }
    }

    final countries = productionCountries
        .map((country) => country['name'] as String?)
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    final cast = castJson.take(10).map(MovieCastMember.fromTmdb).toList(growable: false);

    final reviews = reviewsJson
        .map((review) {
          final content = (review['content'] as String?)?.trim() ?? '';
          if (content.isEmpty) return null;

          return MovieReviewData(
            author: (review['author'] as String?)?.trim().isNotEmpty == true
                ? (review['author'] as String).trim()
                : 'Аноним',
            content: content,
            createdAt: DateTime.tryParse((review['created_at'] as String?) ?? ''),
            rating: (review['author_details'] as Map<String, dynamic>?)?['rating'] == null
                ? null
                : ((review['author_details'] as Map<String, dynamic>)['rating'] as num).toDouble(),
          );
        })
        .whereType<MovieReviewData>()
        .take(10)
        .toList(growable: false);

    final voteAverage = ((json['vote_average'] as num?) ?? 0).toDouble();
    final voteCount = (json['vote_count'] as num?)?.toInt() ?? 0;
    final ageRating = _extractAgeRating(
      ((json['release_dates'] as Map<String, dynamic>?)?['results']
              as List<dynamic>? ??
          [])
          .cast<Map<String, dynamic>>(),
    );
    final tagline = (json['tagline'] as String?)?.trim();
    final originalTitle = (json['original_title'] as String?)?.trim();
    final status = (json['status'] as String?)?.trim();
    final releaseDate = DateTime.tryParse((json['release_date'] as String?) ?? '');

    return MovieFullDetailsData(
      genres: genres,
      runtimeMinutes: runtime,
      overview: overview,
      trailerYoutubeId: trailerYoutubeId,
      director: director,
      countries: countries,
      cast: cast,
      reviews: reviews,
      voteAverage: voteAverage,
      voteCount: voteCount,
      ageRating: ageRating,
      tagline: tagline == null || tagline.isEmpty ? null : tagline,
      originalTitle: originalTitle == null || originalTitle.isEmpty ? null : originalTitle,
      status: status == null || status.isEmpty ? null : status,
      releaseDate: releaseDate,
    );
  }

  String? _extractAgeRating(List<Map<String, dynamic>> releaseDateResults) {
    const priority = ['RU', 'US'];
    for (final country in priority) {
      final value = _extractCertificationForCountry(releaseDateResults, country);
      if (value != null) return value;
    }

    for (final countryResult in releaseDateResults) {
      final value = _extractCertificationForCountry(
        releaseDateResults,
        countryResult['iso_3166_1']?.toString(),
      );
      if (value != null) return value;
    }
    return null;
  }

  String? _extractCertificationForCountry(
    List<Map<String, dynamic>> releaseDateResults,
    String? countryCode,
  ) {
    if (countryCode == null || countryCode.isEmpty) return null;

    for (final result in releaseDateResults) {
      if (result['iso_3166_1'] != countryCode) continue;
      final releaseDates = (result['release_dates'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      for (final release in releaseDates) {
        final certification = (release['certification'] as String?)?.trim();
        if (certification != null && certification.isNotEmpty) {
          return certification;
        }
      }
    }
    return null;
  }

  String? _extractTrailerYoutubeId(List<Map<String, dynamic>> videos) {
    for (final video in videos) {
      if (video['site'] == 'YouTube' &&
          video['type'] == 'Trailer' &&
          video['official'] == true) {
        final key = video['key'] as String?;
        if (key != null && key.isNotEmpty) return key;
      }
    }
    for (final video in videos) {
      if (video['site'] == 'YouTube' && video['type'] == 'Trailer') {
        final key = video['key'] as String?;
        if (key != null && key.isNotEmpty) return key;
      }
    }
    for (final video in videos) {
      if (video['site'] == 'YouTube') {
        final key = video['key'] as String?;
        if (key != null && key.isNotEmpty) return key;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _getJson(String path, {String extraQuery = ''}) async {
    final uri = Uri.parse(
      '$_apiBaseUrl$path?api_key=$_apiKey&language=$_language&page=1$extraQuery',
    );
    final response = await http.get(uri);

    if (response.statusCode >= 400) {
      throw Exception('TMDb вернул ошибку ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
