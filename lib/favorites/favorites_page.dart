import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  static const List<_FavoriteMovie> _favoriteMovies = [
    _FavoriteMovie(title: 'Дюна: Часть вторая', genre: 'Sci-Fi, Приключения'),
    _FavoriteMovie(title: 'Оппенгеймер', genre: 'Драма, История'),
    _FavoriteMovie(title: 'Человек-паук: Паутина', genre: 'Мультфильм, Экшн'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранные')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteMovies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final movie = _favoriteMovies[index];
          return Card(
            color: const Color(0xFF1D1D1D),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x33E53935),
                child: Icon(Icons.favorite, color: Color(0xFFE53935)),
              ),
              title: Text(movie.title),
              subtitle: Text(
                '${movie.genre}\nДанные о фильме сейчас заглушка (без БД/API)',
                style: const TextStyle(color: Color(0xFF9A9A9A)),
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.bookmark_remove_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Функция удаления появится после интеграции API'),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteMovie {
  const _FavoriteMovie({required this.title, required this.genre});

  final String title;
  final String genre;
}
