import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  static const List<_FavoriteMovie> _mockFavorites = [
    _FavoriteMovie(
      title: 'Дюна: Часть 2',
      genre: 'Фантастика',
      rating: '8.7',
    ),
    _FavoriteMovie(
      title: 'Оппенгеймер',
      genre: 'Драма',
      rating: '8.5',
    ),
    _FavoriteMovie(
      title: 'Человек-паук: Паутина вселенных',
      genre: 'Анимация',
      rating: '8.6',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранные')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockFavorites.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _NoticeCard(
              text:
                  'Список избранного сейчас на заглушках. Позже подключим хранение через БД/API.',
            );
          }

          final movie = _mockFavorites[index - 1];
          return Card(
            color: const Color(0xFF1D1D1D),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x22E53935),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE53935),
                ),
              ),
              title: Text(movie.title),
              subtitle: Text(
                '${movie.genre} • ⭐ ${movie.rating}',
                style: const TextStyle(color: Color(0xFF9A9A9A)),
              ),
              trailing: const Icon(Icons.chevron_right),
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
    required this.rating,
  });

  final String title;
  final String genre;
  final String rating;
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ),
        ],
      ),
    );
  }
}
