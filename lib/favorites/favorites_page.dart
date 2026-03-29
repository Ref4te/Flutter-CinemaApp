import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  static const List<_FavoriteMovie> _favorites = [
    _FavoriteMovie(
      title: 'Дюна: Часть вторая',
      genre: 'Фантастика, Экшн',
      duration: '166 мин',
    ),
    _FavoriteMovie(
      title: 'Человек-паук: Нет пути домой',
      genre: 'Боевик, Приключения',
      duration: '148 мин',
    ),
    _FavoriteMovie(
      title: 'Оппенгеймер',
      genre: 'Драма, Биография',
      duration: '180 мин',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранные')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final movie = _favorites[index];
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
                child: Container(
                  width: 46,
                  height: 64,
                  color: const Color(0xFF2E2E2E),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.movie_creation_outlined,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
              title: Text(movie.title),
              subtitle: Text(
                '${movie.genre} • ${movie.duration}',
                style: const TextStyle(color: Color(0xFF9A9A9A)),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Color(0xFFE53935)),
                onPressed: () {},
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteMovie {
  const _FavoriteMovie({
    required this.title,
    required this.genre,
    required this.duration,
  });

  final String title;
  final String genre;
  final String duration;
}
