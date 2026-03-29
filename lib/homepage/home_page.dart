import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/images/logo2.svg',
          height: 60,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PromoCard(),
          SizedBox(height: 16),
          _SectionTitle('Скоро в кино'),
          SizedBox(height: 8),
          _PlaceholderMovieTile(
            title: 'Dune: Part Three',
            subtitle: 'Премьера: 12.10.2026 (заглушка)',
          ),
          _PlaceholderMovieTile(
            title: 'Avatar: New Tide',
            subtitle: 'Премьера: 18.11.2026 (заглушка)',
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Добро пожаловать в CinemaApp',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Данные фильмов и афиши сейчас работают на заглушках. '
              'Подключение БД/API добавим позже.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _PlaceholderMovieTile extends StatelessWidget {
  const _PlaceholderMovieTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.local_movies_rounded, color: Colors.amber),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
