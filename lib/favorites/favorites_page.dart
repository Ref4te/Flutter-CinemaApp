import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  static const List<_FavoriteMovieStub> _favorites = [
    _FavoriteMovieStub(
      title: 'Интерстеллар',
      genre: 'Фантастика',
      duration: '2ч 49м',
      posterUrl:
          'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?auto=format&fit=crop&w=800&q=80',
    ),
    _FavoriteMovieStub(
      title: 'Дюна',
      genre: 'Приключения',
      duration: '2ч 35м',
      posterUrl:
          'https://images.unsplash.com/photo-1542204165-65bf26472b9b?auto=format&fit=crop&w=800&q=80',
    ),
    _FavoriteMovieStub(
      title: 'Бегущий по лезвию 2049',
      genre: 'Триллер',
      duration: '2ч 44м',
      posterUrl:
          'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final movie = _favorites[index];
          return Card(
            color: const Color(0xFF1D1D1D),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  movie.posterUrl,
                  width: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 56,
                    child: Icon(Icons.movie_creation_outlined),
                  ),
                ),
              ),
              title: Text(movie.title),
              subtitle: Text('${movie.genre} • ${movie.duration}'),
              trailing: const Icon(Icons.favorite, color: Color(0xFFE53935)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Детали "${movie.title}" будут загружаться с API.'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteMovieStub {
  const _FavoriteMovieStub({
    required this.title,
    required this.genre,
    required this.duration,
    required this.posterUrl,
  });

  final String title;
  final String genre;
  final String duration;
  final String posterUrl;
}
