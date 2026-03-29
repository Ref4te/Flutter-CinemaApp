import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 1);
  int _activeBannerIndex = 0;
  int _activeCategoryIndex = 0;

  final List<_BannerItem> _banners = const [
    _BannerItem(
      title: 'Первому игроку приготовиться',
      imageUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=1400&q=80',
    ),
    _BannerItem(
      title: 'Интерстеллар',
      imageUrl:
          'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?auto=format&fit=crop&w=1400&q=80',
    ),
    _BannerItem(
      title: 'Бегущий по лезвию 2049',
      imageUrl:
          'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  final List<String> _categories = const ['Все', 'Экшн', 'Комедия', 'Блокбастер', 'Романы'];

  final List<_MovieItem> _movies = const [
    _MovieItem(
      title: 'Звездные войны',
      category: 'Блокбастер',
      year: 2019,
      duration: '2 ч 22 мин',
      rating: 8.1,
      description:
          'Эпичная космическая сага о противостоянии Света и Тьмы, где судьба галактики решается в последней битве джедаев и ситхов.',
      imageUrl:
          'https://images.unsplash.com/photo-1536440136628-849c177e76a1?auto=format&fit=crop&w=900&q=80',
    ),
    _MovieItem(
      title: 'Достать ножи',
      category: 'Комедия',
      year: 2019,
      duration: '2 ч 10 мин',
      rating: 7.9,
      description:
          'Детективная история с острым юмором, в которой знаменитый сыщик расследует загадочное убийство в богатой семье.',
      imageUrl:
          'https://images.unsplash.com/photo-1478720568477-152d9b164e26?auto=format&fit=crop&w=900&q=80',
    ),
    _MovieItem(
      title: 'Вперед',
      category: 'Романы',
      year: 2020,
      duration: '1 ч 42 мин',
      rating: 7.4,
      description:
          'Трогательная история о семье и дружбе, где герои отправляются в путешествие, чтобы вернуть магию в привычный мир.',
      imageUrl:
          'https://images.unsplash.com/photo-1503095396549-807759245b35?auto=format&fit=crop&w=900&q=80',
    ),
    _MovieItem(
      title: 'Мулан',
      category: 'Экшн',
      year: 2020,
      duration: '1 ч 55 мин',
      rating: 7.2,
      description:
          'Юная воительница отправляется на войну вместо отца и проходит путь от новобранца до легенды, защищая свою страну.',
      imageUrl:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  List<_MovieItem> get _filteredMovies {
    final selectedCategory = _categories[_activeCategoryIndex];
    if (selectedCategory == 'Все') {
      return _movies;
    }
    return _movies
        .where((movie) => movie.category == selectedCategory)
        .toList(growable: false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset('assets/images/logo2.svg', height: 38),
        actions: [
          IconButton(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Добро пожаловать в ',
                      style: TextStyle(color: Color(0xFFB0B0B0)),
                    ),
                    TextSpan(
                      text: 'Коршиш',
                      style: TextStyle(color: Color(0xFFE53935)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 210,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _banners.length,
                  onPageChanged: (index) {
                    setState(() => _activeBannerIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _PosterImage(url: banner.imageUrl),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xA6000000),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  banner.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (index) {
                  final isSelected = index == _activeBannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFFE53935) : const Color(0xFF5F5F5F),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = _activeCategoryIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _activeCategoryIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0x33E53935) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE53935)
                                : const Color(0xFF333333),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? const Color(0xFFE53935)
                                : const Color(0xFF9A9A9A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                itemCount: _filteredMovies.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  final movie = _filteredMovies[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _MovieDetailsPage(movie: movie),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: _PosterImage(url: movie.imageUrl),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB8B8B8),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          movie.category,
                          style: const TextStyle(
                            color: Color(0xFF7E7E7E),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF1E1E1E),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF323232), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.movie_outlined, color: Color(0xFF8A8A8A), size: 42),
      ),
    );
  }
}

class _BannerItem {
  const _BannerItem({required this.title, required this.imageUrl});

  final String title;
  final String imageUrl;
}

class _MovieItem {
  const _MovieItem({
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.year,
    required this.duration,
    required this.rating,
    required this.description,
  });

  final String title;
  final String imageUrl;
  final String category;
  final int year;
  final String duration;
  final double rating;
  final String description;
}

class _MovieDetailsPage extends StatelessWidget {
  const _MovieDetailsPage({required this.movie});

  final _MovieItem movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 360,
                width: double.infinity,
                child: _PosterImage(url: movie.imageUrl),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              movie.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MovieMetaChip(icon: Icons.category_outlined, label: movie.category),
                _MovieMetaChip(
                  icon: Icons.calendar_month_outlined,
                  label: movie.year.toString(),
                ),
                _MovieMetaChip(icon: Icons.schedule_outlined, label: movie.duration),
                _MovieMetaChip(
                  icon: Icons.star_rounded,
                  label: movie.rating.toStringAsFixed(1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Описание',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              movie.description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFB8B8B8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieMetaChip extends StatelessWidget {
  const _MovieMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE53935)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCDCDCD),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
