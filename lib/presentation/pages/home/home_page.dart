import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../domain/entities/movie.dart';
import '../../../data/repositories/tmdb_repository.dart';
import '../details/movie_detail_screen.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _HomeCategory { now, soon }

class _HomePageState extends State<HomePage> {
  final TmdbRepository _tmdbRepository = TmdbRepository();

  late Future<TmdbHomeData> _homeDataFuture;
  _HomeCategory _activeCategory = _HomeCategory.now;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _tmdbRepository.loadHomeData();
    AppSettings.language.addListener(_reloadData);
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_reloadData);
    super.dispose();
  }

  void _reloadData() {
    if (!mounted) return;
    setState(() {
      _activeCategory = _HomeCategory.now;
      _homeDataFuture = _tmdbRepository.loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.language,
      builder: (context, language, child) {
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
            child: FutureBuilder<TmdbHomeData>(
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
                    message: AppStrings.t('tmdb_load_error'),
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
                            ? Center(
                          child: Text(
                            AppStrings.t('movies_not_found_by_filter'),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                            ),
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
                                    builder: (_) =>
                                        MovieDetailScreen(movie: movie),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(24),
                                      child: _PosterImage(
                                        url: movie.imageUrl,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 44,
                                    child: Text(
                                      movie.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
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
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          movie.category,
                                          textAlign: TextAlign.left,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
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
      },
    );
  }

  Widget _buildTopBar(BuildContext context, List<MovieItem> movies) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerColor =
    isDark ? const Color(0xFF1A1A1A) : Colors.white;

    final borderColor =
    isDark ? const Color(0xFF323232) : const Color(0xFFE1E4EA);

    final unselectedTextColor =
    isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: isDark
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SwitcherButton(
                    label: AppStrings.t('now_in_cinema'),
                    isSelected: _activeCategory == _HomeCategory.now,
                    unselectedTextColor: unselectedTextColor,
                    onTap: () {
                      setState(() => _activeCategory = _HomeCategory.now);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _SwitcherButton(
                    label: AppStrings.t('soon'),
                    isSelected: _activeCategory == _HomeCategory.soon,
                    unselectedTextColor: unselectedTextColor,
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
            color: containerColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
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

      final releaseDateOnly =
      DateTime(releaseDate.year, releaseDate.month, releaseDate.day);

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
    required this.unselectedTextColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color unselectedTextColor;
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
            color: isSelected ? Colors.white : unselectedTextColor,
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
  String? get searchFieldLabel => AppStrings.t('search');

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
      return Center(
        child: Text(
          AppStrings.t('nothing_found'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
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
          subtitle: Text(
            '${AppStrings.t('rating')} ${movie.rating.toStringAsFixed(1)}',
          ),
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
      return _fallback(context);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          color: Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
            Color(0xFF323232),
            Color(0xFF1A1A1A),
          ]
              : const [
            Color(0xFFE7EAF0),
            Color(0xFFF9FAFB),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_outlined,
        color: isDark ? const Color(0xFF8A8A8A) : const Color(0xFF9CA3AF),
        size: 42,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE53935),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.t('try_again')),
            ),
          ],
        ),
      ),
    );
  }
}