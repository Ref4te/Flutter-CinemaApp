import 'package:flutter/material.dart';

import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1B1B1B);
  static const Color _accentColor = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: const Text(
          'Корщиш',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(text: 'Добро пожаловать в ', style: TextStyle(color: Colors.white70)),
                  TextSpan(text: 'Корщиш', style: TextStyle(color: _accentColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildHeroCard(),
            const SizedBox(height: 18),
            const _PagerIndicator(),
            const SizedBox(height: 18),
            const _GenreTabs(),
            const SizedBox(height: 18),
            const _MovieGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=1200&q=80',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 14,
            child: Text(
              'Новая премьера',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagerIndicator extends StatelessWidget {
  const _PagerIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(active: true),
        SizedBox(width: 8),
        _Dot(),
        SizedBox(width: 8),
        _Dot(),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? HomePage._accentColor : Colors.grey.shade600,
      ),
    );
  }
}

class _GenreTabs extends StatelessWidget {
  const _GenreTabs();

  @override
  Widget build(BuildContext context) {
    final genres = ['Экшн', 'Комедия', 'Блокбастер', 'Романы'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(genres.length, (index) {
          final isActive = index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              children: [
                Text(
                  genres[index],
                  style: TextStyle(
                    color: isActive ? HomePage._accentColor : Colors.white60,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 3,
                  width: 42,
                  color: isActive ? HomePage._accentColor : Colors.transparent,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MovieGrid extends StatelessWidget {
  const _MovieGrid();

  static const _movies = [
    _Movie(title: 'Звездные войны', image: 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?auto=format&fit=crop&w=900&q=80'),
    _Movie(title: 'Достать ножи', image: 'https://images.unsplash.com/photo-1518929458119-e5bf444c30f4?auto=format&fit=crop&w=900&q=80'),
    _Movie(title: 'Вперед', image: 'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?auto=format&fit=crop&w=900&q=80'),
    _Movie(title: 'Мулан', image: 'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?auto=format&fit=crop&w=900&q=80'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: _movies.length,
      itemBuilder: (context, index) {
        final movie = _movies[index];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: HomePage._cardColor,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.network(movie.image, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Movie {
  final String title;
  final String image;

  const _Movie({required this.title, required this.image});
}
