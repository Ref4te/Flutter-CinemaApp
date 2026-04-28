import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../domain/entities/movie.dart';
import '../../../domain/entities/movie_details.dart';
import '../../../domain/entities/session.dart';
import '../../../data/repositories/tmdb_repository.dart';
import '../../../data/repositories/booking_repository.dart';
import 'seat_selection_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final MovieItem movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _tmdbRepository = TmdbRepository();
  final _bookingRepository = BookingRepository();

  YoutubePlayerController? _youtubeController;
  late Future<MovieFullDetailsData> _detailsFuture;

  _TicketDateFilter _activeDate = _TicketDateFilter.today;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadMovieDetails();
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<MovieFullDetailsData> _loadMovieDetails() async {
    final details = await _tmdbRepository.loadMovieFullDetails(widget.movie.id);
    _setupYoutube(details.trailerYoutubeId);
    return details;
  }

  void _setupYoutube(String? trailerYoutubeId) {
    if (trailerYoutubeId == null || trailerYoutubeId.isEmpty) return;

    _youtubeController?.dispose();
    _youtubeController = YoutubePlayerController(
      initialVideoId: trailerYoutubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MovieFullDetailsData>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.movie.title)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Не удалось загрузить данные фильма.\n${snapshot.error ?? ''}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final details = snapshot.data!;
        final youtubeController = _youtubeController;
        if (youtubeController == null) {
          return _buildMovieDetailsScaffold(details: details, trailerPlayer: null);
        }

        return YoutubePlayerBuilder(
          onEnterFullScreen: () {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          },
          onExitFullScreen: () {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
          },
          player: YoutubePlayer(
            controller: youtubeController,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFFE53935),
            onEnded: (_) {
              _youtubeController?.pause();
            },
          ),
          builder: (context, player) =>
              _buildMovieDetailsScaffold(details: details, trailerPlayer: player),
        );
      },
    );
  }

  Widget _buildMovieDetailsScaffold({
    required MovieFullDetailsData details,
    required Widget? trailerPlayer,
  }) {
    final canBookTickets = _isReleasedStatus(details.status);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (_, __) {
                  return [
                    SliverAppBar(
                      floating: false,
                      pinned: true,
                      snap: false,
                      toolbarHeight: 56,
                      expandedHeight: 300,
                      title: Text(
                        widget.movie.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _buildTrailerPlayer(player: trailerPlayer),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? const Color(0xFFE53935) : Colors.white,
                          ),
                          tooltip: 'Избранное',
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildInfoPanel(details),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabsHeaderDelegate(
                        child: Container(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: TabBar(
                            isScrollable: false,
                            tabAlignment: TabAlignment.fill,
                            dividerColor: Colors.transparent,
                            labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A1A),
                            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF888888) : const Color(0xFF777777),
                            indicatorColor: const Color(0xFFE53935),
                            indicatorWeight: 4,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            tabs: const [
                              Tab(text: 'Билеты'),
                              Tab(text: 'О фильме'),
                              Tab(text: 'Отзывы'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    _TicketsTab(
                      movieId: widget.movie.id,
                      movieTitle: widget.movie.title,
                      activeDate: _activeDate,
                      canBookTickets: canBookTickets,
                      onDateSelected: (value) {
                        setState(() => _activeDate = value);
                      },
                    ),
                    _AboutMovieTab(movie: widget.movie, details: details),
                    _ReviewsTab(details: details),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailerPlayer({required Widget? player}) {
    if (player == null) {
      if (widget.movie.imageUrl.isNotEmpty) {
        return Image.network(
          widget.movie.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF1E1E1E),
            alignment: Alignment.center,
            child: const Icon(
              Icons.movie_outlined,
              color: Color(0xFFB8B8B8),
              size: 48,
            ),
          ),
        );
      }
      return Container(
        color: const Color(0xFF1E1E1E),
        alignment: Alignment.center,
        child: const Icon(
          Icons.movie_outlined,
          color: Color(0xFFB8B8B8),
          size: 48,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: player),
    );
  }

  Widget _buildInfoPanel(MovieFullDetailsData details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final genres = details.genres.isNotEmpty
        ? details.genres.take(3).toList(growable: false)
        : <String>[widget.movie.category];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.movie.title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5A5A5A)),
                ),
                child: Text(
                  _buildAgeRatingLabel(details.ageRating),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: genres
                      .map(
                        (genre) => Chip(
                          label: Text(genre),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF1F1),
                          side: BorderSide(color: isDark ? const Color(0xFF474747) : const Color(0xFFFFCFCF)),
                          labelStyle: TextStyle(color: isDark ? const Color(0xFFE4E4E4) : const Color(0xFF9A1F1F)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? <String>[];
      final isFavorite = favorites.contains(widget.movie.id.toString());
      if (!mounted) return;
      setState(() => _isFavorite = isFavorite);
    } on PlatformException catch (error) {
      debugPrint('Не удалось прочитать избранное: $error');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? <String>[];
      final movieId = widget.movie.id.toString();

      if (favorites.contains(movieId)) {
        favorites.remove(movieId);
      } else {
        favorites.add(movieId);
      }

      await prefs.setStringList('favorites', favorites);
      if (!mounted) return;
      setState(() => _isFavorite = favorites.contains(movieId));
    } on PlatformException catch (error) {
      debugPrint('Не удалось обновить избранное: $error');
    }
  }

  bool _isReleasedStatus(String? status) {
    if (status == null) return false;
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    return normalized == 'released' ||
        normalized.contains('вышел') ||
        normalized.contains('выпущен');
  }
}

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabsHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _AboutMovieTab extends StatelessWidget {
  const _AboutMovieTab({required this.movie, required this.details});

  final MovieItem movie;
  final MovieFullDetailsData details;

  @override
  Widget build(BuildContext context) {
    final cast = details.cast;
    final description = details.overview.isNotEmpty ? details.overview : movie.description;
    final durationText = details.runtimeMinutes > 0 ? '${details.runtimeMinutes} мин' : movie.duration;
    final countryText = details.countries.isNotEmpty ? details.countries.join(', ') : 'Не указана';
    final isAnimationMovie = details.genres.any(
      (genre) => genre.toLowerCase().contains('мульт') || genre.toLowerCase().contains('анимац'),
    );
    final castSectionTitle = isAnimationMovie ? 'Актеры озвучки' : 'Актеры';
    final emptyCastMessage = isAnimationMovie
        ? 'Список актеров озвучки недоступен'
        : 'Список актеров недоступен';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFC0C0C0) : const Color(0xFF444444),
          ),
        ),
        if (details.tagline != null) ...[
          const SizedBox(height: 10),
          Text(
            details.tagline!,
            style: const TextStyle(
              color: Color(0xFF9F9F9F),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          castSectionTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: cast.isEmpty
              ? Center(
                  child: Text(
                    emptyCastMessage,
                    style: const TextStyle(color: Color(0xFF9A9A9A)),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cast.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final actor = cast[index];
                    final initials = actor.name
                        .split(' ')
                        .where((part) => part.trim().isNotEmpty)
                        .take(2)
                        .map((part) => part.trim()[0].toUpperCase())
                        .join();
                    return SizedBox(
                      width: 88,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFE53935),
                            backgroundImage: actor.profileImageUrl == null
                                ? null
                                : NetworkImage(actor.profileImageUrl!),
                            child: actor.profileImageUrl == null
                                ? Text(
                                    initials.isNotEmpty ? initials : '?',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            actor.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Детали',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _DetailRow(label: 'Режиссер', value: details.director ?? 'Не указан'),
        _DetailRow(label: 'Длительность', value: durationText),
        _DetailRow(label: 'Страна', value: countryText),
        _DetailRow(label: 'Дата выхода', value: _formatDate(details.releaseDate)),
        _DetailRow(
          label: 'Оригинал',
          value: details.originalTitle ?? 'Не указано',
        ),
        _DetailRow(label: 'Статус', value: details.status ?? 'Не указан'),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Не указана';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF999999))),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.details});

  final MovieFullDetailsData details;

  @override
  Widget build(BuildContext context) {
    final reviews = details.reviews;
    final ratingText = details.voteAverage > 0 ? '${details.voteAverage.toStringAsFixed(1)} / 10' : '— / 10';
    final reviewCountText = details.voteCount > 0 ? 'на основе ${details.voteCount} оценок' : 'оценки пока недоступны';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1B1B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE53935)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ratingText, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(reviewCountText, style: const TextStyle(color: Color(0xFFB0B0B0))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (reviews.isEmpty)
          const Text(
            'Отзывов пока нет.',
            style: TextStyle(color: Color(0xFFABABAB)),
          )
        else
          ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final MovieReviewData review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.author, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(_formatDate(review.createdAt), style: const TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < ((review.rating ?? 0) / 2).round() ? Icons.star : Icons.star_border,
                color: const Color(0xFFE53935),
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(review.content, style: const TextStyle(color: Color(0xFFD4D4D4), height: 1.35)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Без даты';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}

class _TicketsTab extends StatelessWidget {
  const _TicketsTab({
    required this.movieId,
    required this.movieTitle,
    required this.activeDate,
    required this.canBookTickets,
    required this.onDateSelected,
  });

  final int movieId;
  final String movieTitle;
  final _TicketDateFilter activeDate;
  final bool canBookTickets;
  final ValueChanged<_TicketDateFilter> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final panelBorder = isDark ? const Color(0xFF353535) : const Color(0xFFE4E4E4);
    final chipIdle = isDark ? const Color(0xFF232323) : const Color(0xFFF3F3F3);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final items = <(_TicketDateFilter, String)>[
      (_TicketDateFilter.today, 'Сегодня'),
      (_TicketDateFilter.tomorrow, 'Завтра'),
      (_TicketDateFilter.dayAfterTomorrow, 'Послезавтра'),
    ];

    return StreamBuilder<List<MovieSession>>(
      stream: BookingRepository().getSessions(movieId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final sessions = snapshot.data ?? [];
        final filteredSessions = _filterSessionsByDate(sessions, activeDate);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: panelBorder),
              ),
              child: Row(
                children: items.map((item) {
                  final (filter, title) = item;
                  final isSelected = activeDate == filter;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => onDateSelected(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE53935)
                                : chipIdle,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (filteredSessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Нет доступных сеансов на эту дату', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ..._groupSessionsByCinema(filteredSessions).entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: panelBorder),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(entry.key),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((session) {
                        final timeStr = "${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}";
                        return OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeatSelectionScreen(
                                  sessionId: session.id,
                                  movieTitle: movieTitle,
                                  hallName: 'Зал ${session.hallId}',
                                  sessionTime: timeStr,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4A4A4A)),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(timeStr),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }
    );
  }

  List<MovieSession> _filterSessionsByDate(List<MovieSession> sessions, _TicketDateFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final targetDate = switch (filter) {
      _TicketDateFilter.today => today,
      _TicketDateFilter.tomorrow => today.add(const Duration(days: 1)),
      _TicketDateFilter.dayAfterTomorrow => today.add(const Duration(days: 2)),
    };

    return sessions.where((s) {
      final sDate = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      bool isCorrectDate = sDate.isAtSameMomentAs(targetDate);
      if (isCorrectDate && filter == _TicketDateFilter.today) {
        return s.startTime.isAfter(now);
      }
      return isCorrectDate;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Map<String, List<MovieSession>> _groupSessionsByCinema(List<MovieSession> sessions) {
    Map<String, List<MovieSession>> grouped = {};
    for (var s in sessions) {
      grouped.putIfAbsent(s.cinemaName, () => []).add(s);
    }
    return grouped;
  }
}

enum _TicketDateFilter { today, tomorrow, dayAfterTomorrow }

String _buildAgeRatingLabel(String? rawRating) {
  final rating = rawRating?.trim();
  if (rating == null || rating.isEmpty) return '—';
  if (rating.endsWith('+')) return rating;
  return '$rating+';
}
