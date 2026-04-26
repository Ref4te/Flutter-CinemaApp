import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../core/settings/app_settings.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';

class TmdbRepository {
  static const String _apiBaseUrl = 'https://api.themoviedb.org/3';
  static String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  String get _language {
    final lang = AppSettings.language.value;

    if (lang == 'Қазақша') {
      return 'ru-RU'; // fallback вместо kk-KZ
    }

    if (lang == 'English') {
      return 'en-US';
    }

    return 'ru-RU';
  }

  Future<TmdbHomeData> loadHomeData() async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'TMDb API key не найден. Передайте ключ через --dart-define=TMDB_API_KEY=... ',
      );
    }

    final genreMap = await _loadGenres();
    final discoverPage1Response = await _getJson(
      '/discover/movie',
      extraQuery: '&region=KZ&sort_by=popularity.desc&include_adult=false',
    );
    final discoverPage2Response = await _getJson(
      '/discover/movie',
      extraQuery: '&region=KZ&sort_by=popularity.desc&include_adult=false&page=2',
    );
    final trendingResponse = await _getJson('/trending/movie/week');

    final rawDiscoverPage1Movies =
    (discoverPage1Response['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final rawDiscoverPage2Movies =
    (discoverPage2Response['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final rawBanners =
    (trendingResponse['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final combinedMovies = <Map<String, dynamic>>[
      ...rawDiscoverPage1Movies,
      ...rawDiscoverPage2Movies,
    ];

    final uniqueMoviesById = <int, Map<String, dynamic>>{};

    for (final movie in combinedMovies) {
      final id = movie['id'] as int?;
      if (id == null) continue;
      uniqueMoviesById[id] = movie;
    }

    final movies = uniqueMoviesById.values
        .where((movie) => (movie['poster_path'] as String?)?.isNotEmpty == true)
        .where((movie) =>
    (movie['release_date'] as String?)?.trim().isNotEmpty == true)
        .take(40)
        .map((movie) => MovieItem.fromTmdb(movie, genreMap: genreMap))
        .toList(growable: false);

    final banners = rawBanners
        .where((movie) => (movie['backdrop_path'] as String?)?.isNotEmpty == true)
        .take(5)
        .map(BannerItem.fromTmdb)
        .toList(growable: false);

    return TmdbHomeData(banners: banners, movies: movies);
  }

  Future<Map<int, String>> _loadGenres() async {
    final json = await _getJson('/genre/movie/list');
    final genres =
    (json['genres'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return {
      for (final genre in genres)
        if (genre['id'] is int && genre['name'] is String)
          genre['id'] as int: genre['name'] as String,
    };
  }

  Future<MovieDetailsData> loadMovieDetails(int movieId) async {
    final json = await _getJson('/movie/$movieId');
    final genresJson =
    (json['genres'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
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

    final genresJson =
    (json['genres'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final runtime = (json['runtime'] as num?)?.toInt() ?? 0;
    final genres = genresJson
        .map((genre) => genre['name'] as String?)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim())
        .toList(growable: false);

    final overview = (json['overview'] as String?)?.trim() ?? '';
    final credits = json['credits'] as Map<String, dynamic>? ?? const {};
    final crew =
    (credits['crew'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final castJson =
    (credits['cast'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final productionCountries =
    (json['production_countries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final reviewsJson =
    ((json['reviews'] as Map<String, dynamic>?)?['results']
    as List<dynamic>? ??
        [])
        .cast<Map<String, dynamic>>();
    final videos =
    ((json['videos'] as Map<String, dynamic>?)?['results']
    as List<dynamic>? ??
        [])
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

    final cast =
    castJson.take(10).map(MovieCastMember.fromTmdb).toList(growable: false);

    final reviews = reviewsJson
        .map((review) {
      final content = (review['content'] as String?)?.trim() ?? '';
      if (content.isEmpty) return null;

      return MovieReviewData(
        author: (review['author'] as String?)?.trim().isNotEmpty == true
            ? (review['author'] as String).trim()
            : 'Аноним',
        content: content,
        createdAt:
        DateTime.tryParse((review['created_at'] as String?) ?? ''),
        rating: (review['author_details'] as Map<String, dynamic>?)?[
        'rating'] ==
            null
            ? null
            : ((review['author_details'] as Map<String, dynamic>)['rating']
        as num)
            .toDouble(),
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
    final releaseDateResults =
    ((json['release_dates'] as Map<String, dynamic>?)?['results']
    as List<dynamic>? ??
        [])
        .cast<Map<String, dynamic>>();

    final releaseDate = _extractReleaseDateByCountry(releaseDateResults, 'KZ') ??
        _extractReleaseDateByCountry(releaseDateResults, 'RU') ??
        DateTime.tryParse((json['release_date'] as String?) ?? '');

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
      originalTitle:
      originalTitle == null || originalTitle.isEmpty ? null : originalTitle,
      status: status == null || status.isEmpty ? null : status,
      releaseDate: releaseDate,
    );
  }

  String? _extractAgeRating(List<Map<String, dynamic>> releaseDateResults) {
    const priority = ['KZ', 'RU', 'US'];

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

      final releaseDates =
      (result['release_dates'] as List<dynamic>? ?? [])
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

  DateTime? _extractReleaseDateByCountry(
      List<Map<String, dynamic>> releaseDateResults,
      String countryCode,
      ) {
    for (final result in releaseDateResults) {
      if (result['iso_3166_1'] != countryCode) continue;

      final releaseDates =
      (result['release_dates'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      for (final release in releaseDates) {
        final date =
        DateTime.tryParse((release['release_date'] as String?) ?? '');

        if (date != null) return date;
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

  Future<Map<String, dynamic>> _getJson(
      String path, {
        String extraQuery = '',
      }) async {
    final normalizedExtra = extraQuery.isEmpty
        ? ''
        : extraQuery.startsWith('&')
        ? extraQuery
        : '&$extraQuery';

    final uri = Uri.parse(
      '$_apiBaseUrl$path?api_key=$_apiKey&language=$_language$normalizedExtra',
    );

    final response = await http.get(uri);

    if (response.statusCode >= 400) {
      throw Exception(
        'TMDb вернул ошибку ${response.statusCode}: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}