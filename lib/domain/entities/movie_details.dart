import 'movie.dart';

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
      profileImageUrl:
          profilePath == null || profilePath.isEmpty ? null : '$_tmdbImageBaseUrl$profilePath',
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

class TmdbHomeData {
  final List<BannerItem> banners;
  final List<MovieItem> movies;

  const TmdbHomeData({required this.banners, required this.movies});
}
