import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../settings/settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<String> _genres = ['Экшн', 'Комедия', 'Блокбастер', 'Романы'];

  static const List<_MovieStub> _movies = [
    _MovieStub(title: 'Звёздные войны', colors: [Color(0xFF5B0E0E), Color(0xFF161616)]),
    _MovieStub(title: 'Достать ножи', colors: [Color(0xFF0B2A46), Color(0xFF191919)]),
    _MovieStub(title: 'Лука', colors: [Color(0xFF2A3EA7), Color(0xFF151520)]),
    _MovieStub(title: 'Мулан', colors: [Color(0xFF7D0B16), Color(0xFF241616)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset('assets/images/logo2.svg', height: 40),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white70),
              children: const [
                TextSpan(text: 'Добро пожаловать в '),
                TextSpan(text: 'Коршиш', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF253240), Color(0xFF131A21), Color(0xFF2A0F30)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.25,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=900&q=80',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded, size: 72, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _Dot(active: true),
              _Dot(active: false),
              _Dot(active: false),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final isSelected = index == 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _genres[index],
                      style: TextStyle(
                        color: isSelected ? Colors.redAccent : Colors.white60,
                        fontSize: 22,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        height: 3,
                        width: 40,
                        color: Colors.redAccent,
                      ),
                  ],
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 28),
              itemCount: _genres.length,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            itemCount: _movies.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.58,
            ),
            itemBuilder: (context, index) {
              final movie = _movies[index];
              return _MovieCard(movie: movie);
            },
          ),
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});

  final _MovieStub movie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: movie.colors,
              ),
            ),
            child: const Center(
              child: Icon(Icons.local_movies_rounded, size: 44, color: Colors.white54),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(movie.title, style: const TextStyle(fontSize: 18, color: Colors.white70)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.redAccent : Colors.white38,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MovieStub {
  const _MovieStub({required this.title, required this.colors});

  final String title;
  final List<Color> colors;
}
