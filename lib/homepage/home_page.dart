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

enum _HomeCategory { now, soon }

enum _DateFilter { today, tomorrow, dayAfterTomorrow }

class _HomePageState extends State<HomePage> {
  final TmdbService _tmdbService = TmdbService();

  late Future<TmdbData> _homeDataFuture;
  _HomeCategory _activeCategory = _HomeCategory.now;
  _DateFilter _activeDate = _DateFilter.today;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _tmdbService.loadHomeData();
  }

  void _reloadData() {
    setState(() {
      _activeCategory = _HomeCategory.now;
      _activeDate = _DateFilter.today;
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
                  _buildDateFilter(),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
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
                    builder: (_) => MovieDetailsPage(movie: selectedMovie),
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

  Widget _buildDateFilter() {
    final items = <(_DateFilter, String)>[
      (_DateFilter.today, 'Сегодня'),
      (_DateFilter.tomorrow, 'Завтра'),
      (_DateFilter.dayAfterTomorrow, 'Послезавтра'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, title) = items[index];
          final isSelected = _activeDate == filter;

          return GestureDetector(
            onTap: () {
              setState(() => _activeDate = filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x33E53935) : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFE53935) : const Color(0xFF343434),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFE53935) : const Color(0xFFAAAAAA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<MovieItem> _applyFilters(List<MovieItem> movies) {
    return movies.where((movie) {
      final isNowPlaying = movie.id.isEven;
      final movieDateFilter = _DateFilter.values[movie.id % _DateFilter.values.length];

      final passCategory = _activeCategory == _HomeCategory.now
          ? isNowPlaying
          : !isNowPlaying;
      final passDate = movieDateFilter == _activeDate;

      return passCategory && passDate;
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
