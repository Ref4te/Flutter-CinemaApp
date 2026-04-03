import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 1);
  final TmdbService _tmdbService = TmdbService();

  late Future<TmdbData> _homeDataFuture;
  int _activeBannerIndex = 0;
  int _activeCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _tmdbService.loadHomeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _reloadData() {
    setState(() {
      _activeBannerIndex = 0;
      _activeCategoryIndex = 0;
      _homeDataFuture = _tmdbService.loadHomeData();
    });
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
        child: FutureBuilder<TmdbData>(
          future: _homeDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _reloadData,
              );
            }

            final data = snapshot.data;
            if (data == null || data.movies.isEmpty) {
              return _ErrorState(
                message: 'Не удалось получить фильмы из TMDb.',
                onRetry: _reloadData,
              );
            }

            final categories = _buildCategories(data.movies);
            final selectedCategory = categories[_activeCategoryIndex];
            final filteredMovies = _filterMovies(data.movies, selectedCategory);

            return SingleChildScrollView(
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
                          text: 'Көрщищ',
                          style: TextStyle(color: Color(0xFFE53935)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data.banners.isNotEmpty) ...[
                    SizedBox(
                      height: 210,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: data.banners.length,
                        onPageChanged: (index) {
                          setState(() => _activeBannerIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final banner = data.banners[index];
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
                      children: List.generate(data.banners.length, (index) {
                        final isSelected = index == _activeBannerIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFFE53935)
                                : const Color(0xFF5F5F5F),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final isSelected = _activeCategoryIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => _activeCategoryIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0x33E53935)
                                  : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF333333),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              categories[index],
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
                    itemCount: filteredMovies.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemBuilder: (context, index) {
                      final movie = filteredMovies[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailsPage(movie: movie),
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
                                color: Color(0xFF7A7A7A),
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
            );
          },
        ),
      ),
    );
  }

  List<String> _buildCategories(List<MovieItem> movies) {
    final categories = <String>{'Все'};
    for (final movie in movies) {
      categories.add(movie.category);
    }
    return categories.toList(growable: false);
  }

  List<MovieItem> _filterMovies(List<MovieItem> movies, String selectedCategory) {
    if (selectedCategory == 'Все') {
      return movies;
    }
    return movies
        .where((movie) => movie.category == selectedCategory)
        .toList(growable: false);
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _fallback();
    }

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
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF323232), Color(0xFF1A1A1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined, color: Color(0xFF8A8A8A), size: 42),
    );
  }
}

class MovieDetailsPage extends StatelessWidget {
  const MovieDetailsPage({super.key, required this.movie});

  final MovieItem movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: _PosterImage(url: movie.imageUrl),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            movie.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: movie.category, icon: Icons.movie_filter_outlined),
              _InfoChip(label: '${movie.year}', icon: Icons.calendar_month_outlined),
              _InfoChip(label: movie.duration, icon: Icons.schedule_outlined),
              _InfoChip(
                label: '⭐ ${movie.rating.toStringAsFixed(1)}',
                icon: Icons.star_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Описание',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            movie.description,
            style: const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFFB8B8B8)),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          Text(label, style: const TextStyle(color: Color(0xFFD0D0D0))),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB8B8B8)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }
}
