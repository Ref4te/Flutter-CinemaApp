import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../details/movie_detail_screen.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const _favoritesKey = 'favorites';

  late Future<List<_FavoriteMovieView>> _favoritesFuture;
  final _tmdbService = TmdbService();

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _loadFavorites();
  }

  Future<List<_FavoriteMovieView>> _loadFavorites() async {
    final favoriteIds = await _loadFavoriteIds();
    if (favoriteIds.isEmpty) return const <_FavoriteMovieView>[];

    final homeData = await _tmdbService.loadHomeData();
    final favoriteSet = favoriteIds.toSet();
    final favoriteMovies = homeData.movies
        .where((movie) => favoriteSet.contains(movie.id.toString()))
        .toList(growable: false);

    return Future.wait(
      favoriteMovies.map((movie) async {
        try {
          final details = await _tmdbService.loadMovieDetails(movie.id);
          return _FavoriteMovieView(
            movie: movie,
            genres: details.genres.take(2).toList(growable: false),
            runtimeMinutes: details.runtimeMinutes,
          );
        } catch (_) {
          return _FavoriteMovieView(
            movie: movie,
            genres: [movie.category],
            runtimeMinutes: 0,
          );
        }
      }),
    );
  }

  Future<List<String>> _loadFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_favoritesKey) ?? <String>[];
    } on PlatformException catch (error) {
      debugPrint('Не удалось загрузить избранные ID: $error');
      return <String>[];
    }
  }

  Future<void> _removeFromFavorites(MovieItem movie) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? <String>[];
      favorites.remove(movie.id.toString());
      await prefs.setStringList(_favoritesKey, favorites);
      if (!mounted) return;
      setState(() {
        _favoritesFuture = _loadFavorites();
      });
    } on PlatformException catch (error) {
      debugPrint('Не удалось удалить фильм из избранного: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранные')),
      body: FutureBuilder<List<_FavoriteMovieView>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Не удалось загрузить избранные фильмы.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB0B0B0)),
                ),
              ),
            );
          }

          final movies = snapshot.data ?? const <_FavoriteMovieView>[];
          if (movies.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'У вас пока нет избранных фильмов.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB0B0B0)),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final favoriteMovie = movies[index];
              final movie = favoriteMovie.movie;
              final genresText = favoriteMovie.genres.isEmpty
                  ? movie.category
                  : favoriteMovie.genres.join(', ');
              final runtimeText = favoriteMovie.runtimeMinutes > 0
                  ? '${favoriteMovie.runtimeMinutes} мин'
                  : movie.duration;
              return Card(
                color: const Color(0xFF1D1D1D),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: movie.imageUrl.isEmpty
                        ? Container(
                            width: 46,
                            height: 64,
                            color: const Color(0xFF2E2E2E),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.movie_creation_outlined,
                              color: Color(0xFFE53935),
                            ),
                          )
                        : Image.network(
                            movie.imageUrl,
                            width: 46,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                  ),
                  title: Text(movie.title),
                  subtitle: Text(
                    '$genresText • $runtimeText',
                    style: const TextStyle(color: Color(0xFF9A9A9A)),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailScreen(movie: movie),
                      ),
                    ).then((_) {
                      setState(() {
                        _favoritesFuture = _loadFavorites();
                      });
                    });
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Color(0xFFE53935)),
                    onPressed: () => _removeFromFavorites(movie),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteMovieView {
  const _FavoriteMovieView({
    required this.movie,
    required this.genres,
    required this.runtimeMinutes,
  });

  final MovieItem movie;
  final List<String> genres;
  final int runtimeMinutes;
}
