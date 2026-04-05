import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/movie.dart';
import 'seat_selection_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final MovieItem movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  static const _fallbackTrailerId = 'zSWdZVtXT7E';

  late final YoutubePlayerController _youtubeController;
  _TicketDateFilter _activeDate = _TicketDateFilter.today;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController(
      initialVideoId: _fallbackTrailerId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE53935),
      ),
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      },
      builder: (context, player) => DefaultTabController(
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
                                child: player,
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
                            _buildInfoPanel(),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabsHeaderDelegate(
                          child: Container(
                            color: const Color(0xFF121212),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            child: TabBar(
                              isScrollable: false,
                              tabAlignment: TabAlignment.fill,
                              dividerColor: Colors.transparent,
                              labelColor: Colors.white,
                              unselectedLabelColor: const Color(0xFF888888),
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
                        movieTitle: widget.movie.title,
                        activeDate: _activeDate,
                        onDateSelected: (value) {
                          setState(() => _activeDate = value);
                        },
                        sessions: _sessionsByDate[_activeDate]!,
                      ),
                      _AboutMovieTab(movie: widget.movie),
                      const _ReviewsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    final genres = <String>[widget.movie.category, 'Драма', 'Триллер'];

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
                child: const Text(
                  '18+',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                          backgroundColor: const Color(0xFF1E1E1E),
                          side: const BorderSide(color: Color(0xFF353535)),
                          labelStyle: const TextStyle(color: Color(0xFFD0D0D0)),
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
  const _AboutMovieTab({required this.movie});

  final MovieItem movie;

  @override
  Widget build(BuildContext context) {
    const cast = [
      ('Айдана Нур', 'АН'),
      ('Ержан Серик', 'ЕС'),
      ('Томирис Айт', 'ТА'),
      ('Ильяс Каир', 'ИК'),
      ('Madi Omar', 'MO'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text(
          movie.description,
          style: const TextStyle(fontSize: 16, height: 1.45, color: Color(0xFFCFCFCF)),
        ),
        const SizedBox(height: 18),
        const Text(
          'Актеры',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final (name, initials) = cast[index];
              return SizedBox(
                width: 82,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFE53935),
                      child: Text(
                        initials,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
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
        const _DetailRow(label: 'Режиссер', value: 'Аскар Беков'),
        _DetailRow(label: 'Длительность', value: movie.duration),
        const _DetailRow(label: 'Страна', value: 'Казахстан'),
      ],
    );
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
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    const reviews = [
      _Review(author: 'Nursultan K.', date: '12.03.2026', text: 'Сильная игра актеров, особенно в финале. Сюжет держит до последней сцены.', rating: 9),
      _Review(author: 'Aruzhan M.', date: '10.03.2026', text: 'Красивый визуал и музыка. В середине немного проседает темп, но в целом очень достойно.', rating: 8),
      _Review(author: 'Timur S.', date: '08.03.2026', text: 'Неплохой фильм на вечер, но ожидал чуть более неожиданную развязку.', rating: 7),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF313131)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('8.5 / 10', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('на основе 124 отзывов', style: TextStyle(color: Color(0xFFB0B0B0))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final _Review review;

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
              Text(review.date, style: const TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < (review.rating / 2).round() ? Icons.star : Icons.star_border,
                color: const Color(0xFFE53935),
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(review.text, style: const TextStyle(color: Color(0xFFD4D4D4), height: 1.35)),
        ],
      ),
    );
  }
}

class _TicketsTab extends StatelessWidget {
  const _TicketsTab({
    required this.movieTitle,
    required this.activeDate,
    required this.onDateSelected,
    required this.sessions,
  });

  final String movieTitle;
  final _TicketDateFilter activeDate;
  final ValueChanged<_TicketDateFilter> onDateSelected;
  final List<_CinemaSessions> sessions;

  @override
  Widget build(BuildContext context) {
    final items = <(_TicketDateFilter, String)>[
      (_TicketDateFilter.today, 'Сегодня'),
      (_TicketDateFilter.tomorrow, 'Завтра'),
      (_TicketDateFilter.dayAfterTomorrow, 'Послезавтра'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF353535)),
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
                            : const Color(0xFF232323),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
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
        ...sessions.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: ExpansionTile(
              title: Text(item.cinemaName),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.sessions.map((session) {
                    return OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeatSelectionScreen(
                              sessionId: session.id,
                              movieTitle: movieTitle,
                              hallName: item.cinemaName,
                              sessionTime: session.time,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4A4A4A)),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('${session.time} | ${session.price}тг'),
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
}

enum _TicketDateFilter { today, tomorrow, dayAfterTomorrow }

const Map<_TicketDateFilter, List<_CinemaSessions>> _sessionsByDate = {
  _TicketDateFilter.today: [
    _CinemaSessions(
      cinemaName: 'Kinopark 8 IMAX Saryarka',
      sessions: [
        _Session(id: 'KP8-1400', time: '14:00', price: 2500),
        _Session(id: 'KP8-1830', time: '18:30', price: 3500),
        _Session(id: 'KP8-2110', time: '21:10', price: 3900),
      ],
    ),
    _CinemaSessions(
      cinemaName: 'Chaplin MEGA Silk Way',
      sessions: [
        _Session(id: 'CHM-1320', time: '13:20', price: 2800),
        _Session(id: 'CHM-1650', time: '16:50', price: 3200),
      ],
    ),
  ],
  _TicketDateFilter.tomorrow: [
    _CinemaSessions(
      cinemaName: 'Arman 3D Asia Park',
      sessions: [
        _Session(id: 'ARM-1200', time: '12:00', price: 2300),
        _Session(id: 'ARM-1740', time: '17:40', price: 3000),
      ],
    ),
  ],
  _TicketDateFilter.dayAfterTomorrow: [
    _CinemaSessions(
      cinemaName: 'Kinopark 6 KeruenCity',
      sessions: [
        _Session(id: 'KPK-1500', time: '15:00', price: 2600),
        _Session(id: 'KPK-1945', time: '19:45', price: 3600),
      ],
    ),
  ],
};

class _CinemaSessions {
  final String cinemaName;
  final List<_Session> sessions;

  const _CinemaSessions({required this.cinemaName, required this.sessions});
}

class _Session {
  final String id;
  final String time;
  final int price;

  const _Session({required this.id, required this.time, required this.price});
}

class _Review {
  final String author;
  final String date;
  final String text;
  final int rating;

  const _Review({
    required this.author,
    required this.date,
    required this.text,
    required this.rating,
  });
}
