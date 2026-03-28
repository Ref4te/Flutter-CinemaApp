import 'package:flutter/material.dart';

import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<String> _genres = <String>[
    'Экшн',
    'Комедия',
    'Блокбастер',
    'Романы',
  ];

  int _selectedGenreIndex = 0;

  static const List<_MoviePlaceholder> _movies = <_MoviePlaceholder>[
    _MoviePlaceholder(title: 'Звёздные войны', color: Color(0xFF3D5AFE)),
    _MoviePlaceholder(title: 'Достать ножи', color: Color(0xFF6D4C41)),
    _MoviePlaceholder(title: 'Вперёд', color: Color(0xFF00897B)),
    _MoviePlaceholder(title: 'Мулан', color: Color(0xFFD32F2F)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Добро пожаловать в Корцшщ',
          style: TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 30,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildPagerDots(),
            const SizedBox(height: 20),
            _buildGenreSelector(),
            const SizedBox(height: 20),
            _buildMoviesGrid(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1B1B1B),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Домой',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Избранные',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number_rounded),
            label: 'Билеты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
        onTap: (_) {},
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF424242), Color(0xFF1E88E5), Color(0xFF0B0B0B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            left: 24,
            bottom: 24,
            child: Icon(Icons.movie_filter_rounded, size: 60, color: Colors.white70),
          ),
          Center(
            child: Text(
              'Баннер фильма\n(заглушка)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagerDots() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(active: true),
        SizedBox(width: 8),
        _Dot(active: false),
        SizedBox(width: 8),
        _Dot(active: false),
      ],
    );
  }

  Widget _buildGenreSelector() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final bool selected = index == _selectedGenreIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedGenreIndex = index;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _genres[index],
                  style: TextStyle(
                    fontSize: 18,
                    color: selected ? Colors.redAccent : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 38,
                  height: 3,
                  decoration: BoxDecoration(
                    color: selected ? Colors.redAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoviesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        final movie = _movies[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      movie.color.withOpacity(0.9),
                      movie.color.withOpacity(0.45),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_movies_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.redAccent : Colors.grey,
      ),
    );
  }
}

class _MoviePlaceholder {
  const _MoviePlaceholder({required this.title, required this.color});

  final String title;
  final Color color;
}
