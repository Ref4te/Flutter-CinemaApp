import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const favoriteMovies = [
      {'title': 'Interstellar', 'genre': 'Sci‑Fi'},
      {'title': 'Inception', 'genre': 'Action / Sci‑Fi'},
      {'title': 'The Batman', 'genre': 'Action / Drama'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Избранные')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Список избранного сейчас на заглушках. '
                'Позже сюда подключим БД/API пользователя.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...favoriteMovies.map(
            (movie) => Card(
              child: ListTile(
                leading: const Icon(Icons.favorite_rounded, color: Colors.red),
                title: Text(movie['title']!),
                subtitle: Text(movie['genre']!),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
