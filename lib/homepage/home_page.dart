import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../details/movie_detail_screen.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _HomeCategory { now, soon }

class _HomePageState extends State<HomePage> {
  final TmdbService _tmdbService = TmdbService();

  late Future<TmdbData> _homeDataFuture;
  _HomeCategory _activeCategory = _HomeCategory.now;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _tmdbService.loadHomeData();
  }

  void _reloadData() {
    setState(() {
      _activeCategory = _HomeCategory.now;
      _homeDataFuture = _tmdbService.loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
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

            final filteredMovies = _applyFilters(data.movies);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context, data.movies),
                  const SizedBox(height: 14),
                  Expanded(
                    child: filteredMovies.isEmpty
                        ? const Center(
                            child: Text(
                              'По текущим фильтрам фильмов не найдено.',
                              style: TextStyle(color: Color(0xFFB0B0B0)),
                            ),
                          )
                        : GridView.builder(
                            itemCount: filteredMovies.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.63,
                                ),
                            itemBuilder: (context, index) {
                              final movie = filteredMovies[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailScreen(movie: movie),
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
                                    SizedBox(
                                      height: 44,
                                      child: Text(
                                        movie.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFB8B8B8),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: Color(0xFFE53935),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          movie.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Color(0xFFDADADA),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        Flexible(
                                          child: Text(
                                            movie.category,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF8E8E8E),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, List<MovieItem> movies) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF323232)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SwitcherButton(
                    label: 'Сейчас в кино',
                    isSelected: _activeCategory == _HomeCategory.now,
                    onTap: () {
                      setState(() => _activeCategory = _HomeCategory.now);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _SwitcherButton(
                    label: 'Скоро',
                    isSelected: _activeCategory == _HomeCategory.soon,
                    onTap: () {
                      setState(() => _activeCategory = _HomeCategory.soon);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF323232)),
          ),
          child: IconButton(
            onPressed: () {
              showSearch<MovieItem?>(
                context: context,
                delegate: _MovieSearchDelegate(movies: movies),
              ).then((selectedMovie) {
                if (selectedMovie == null || !context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(movie: selectedMovie),
                  ),
                );
              });
            },
            icon: const Icon(Icons.search_rounded),
          ),
        ),
      ],
    );
  }

  List<MovieItem> _applyFilters(List<MovieItem> movies) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return movies.where((movie) {
      final releaseDate = movie.releaseDate;
      if (releaseDate == null) return false;
      final releaseDateOnly = DateTime(releaseDate.year, releaseDate.month, releaseDate.day);

      final passCategory = _activeCategory == _HomeCategory.now
          ? !releaseDateOnly.isAfter(todayStart)
          : releaseDateOnly.isAfter(todayStart);
      return passCategory;
    }).toList(growable: false);
  }
}

class _SwitcherButton extends StatelessWidget {
  const _SwitcherButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _MovieSearchDelegate extends SearchDelegate<MovieItem?> {
  _MovieSearchDelegate({required this.movies});

  final List<MovieItem> movies;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final results = normalized.isEmpty
        ? movies
        : movies
              .where((movie) => movie.title.toLowerCase().contains(normalized))
              .toList(growable: false);

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final movie = results[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 58,
              child: _PosterImage(url: movie.imageUrl),
            ),
          ),
          title: Text(movie.title),
          subtitle: Text('Рейтинг ${movie.rating.toStringAsFixed(1)}'),
          onTap: () => close(context, movie),
        );
      },
    );
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
