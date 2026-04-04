import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/movie.dart';
import 'seat_selection_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final MovieItem movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

enum _TicketsDateFilter { today, tomorrow, dayAfterTomorrow }

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  static const _trailerUrl = 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4';

  late VideoPlayerController _videoController;
  late Future<void> _videoInitialization;
  _TicketsDateFilter _activeDate = _TicketsDateFilter.today;

  final List<_ActorItem> _actors = const [
    _ActorItem(name: 'Timothée Chalamet'),
    _ActorItem(name: 'Zendaya'),
    _ActorItem(name: 'Rebecca Ferguson'),
    _ActorItem(name: 'Florence Pugh'),
    _ActorItem(name: 'Javier Bardem'),
  ];

  final List<_ReviewItem> _reviews = const [
    _ReviewItem(
      author: 'Aruzhan S.',
      date: '02.04.2026',
      text: 'Визуал сильный, звук в IMAX топ. Сюжет местами затянут, но в целом очень достойно.',
      rating: 4.5,
    ),
    _ReviewItem(
      author: 'Nurlan K.',
      date: '31.03.2026',
      text: 'Актеры отлично сыграли. Для фанатов фантастики — мастхэв.',
      rating: 4.0,
    ),
    _ReviewItem(
      author: 'Dana M.',
      date: '30.03.2026',
      text: 'Картинка шикарная, но хотелось чуть больше экшена во второй половине фильма.',
      rating: 3.5,
    ),
  ];

  final List<_CinemaItem> _cinemas = const [
    _CinemaItem(name: 'Kinopark 11', sessions: [
      _SessionItem(id: 'kp11-1400', time: '14:00', price: 2500),
      _SessionItem(id: 'kp11-1830', time: '18:30', price: 3500),
      _SessionItem(id: 'kp11-2110', time: '21:10', price: 3800),
    ]),
    _CinemaItem(name: 'Chaplin Mega', sessions: [
      _SessionItem(id: 'cm-1230', time: '12:30', price: 2200),
      _SessionItem(id: 'cm-1700', time: '17:00', price: 3200),
      _SessionItem(id: 'cm-2030', time: '20:30', price: 3600),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(_trailerUrl));
    _videoInitialization = _videoController.initialize();
    _videoController.setLooping(false);
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              title: Text(widget.movie.title),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: FutureBuilder<void>(
                        future: _videoInitialization,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          return FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: _videoController.value.size.width,
                              height: _videoController.value.size.height,
                              child: VideoPlayer(_videoController),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_videoController.value.isPlaying) {
                                  _videoController.pause();
                                } else {
                                  _videoController.play();
                                }
                                setState(() {});
                              },
                              icon: Icon(
                                _videoController.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),
                            Expanded(
                              child: VideoProgressIndicator(
                                _videoController,
                                allowScrubbing: true,
                                padding: const EdgeInsets.only(right: 12),
                                colors: VideoProgressColors(
                                  playedColor: Color(0xFFE53935),
                                  bufferedColor: Color(0x80FFFFFF),
                                  backgroundColor: Color(0x50FFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildInfoPanel()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeaderDelegate(
                TabBar(
                  tabs: const [
                    Tab(text: 'Билеты'),
                    Tab(text: 'О фильме'),
                    Tab(text: 'Отзывы'),
                  ],
                  indicatorColor: const Color(0xFFE53935),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF9A9A9A),
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildTicketsTab(),
              _buildAboutTab(),
              _buildReviewsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    final genres = [widget.movie.category, 'Приключения', 'Фантастика'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: const Color(0xFF141414),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movie.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF646464)),
                ),
                child: const Text('18+'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres.map((genre) => Chip(label: Text(genre))).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.movie.description,
          style: const TextStyle(color: Color(0xFFD3D3D3), height: 1.5),
        ),
        const SizedBox(height: 20),
        const Text('Актеры', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _actors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final actor = _actors[index];
              return SizedBox(
                width: 90,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF2B2B2B),
                      child: Text(actor.name.substring(0, 1)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actor.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text('Детали', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _detailRow('Режиссер', 'Denis Villeneuve'),
        _detailRow('Длительность', widget.movie.duration),
        _detailRow('Страна', 'США'),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1D),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('8.5 / 10', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('на основе 124 отзывов', style: TextStyle(color: Color(0xFFB8B8B8))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._reviews.map(
          (review) => Card(
            color: const Color(0xFF1D1D1D),
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(review.author, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(review.date, style: const TextStyle(color: Color(0xFFB8B8B8))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 2,
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating.floor()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 18,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(review.text),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsTab() {
    final items = <(_TicketsDateFilter, String)>[
      (_TicketsDateFilter.today, 'Сегодня'),
      (_TicketsDateFilter.tomorrow, 'Завтра'),
      (_TicketsDateFilter.dayAfterTomorrow, 'Послезавтра'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (date, title) = items[index];
              final isSelected = _activeDate == date;
              return ChoiceChip(
                selected: isSelected,
                onSelected: (_) => setState(() => _activeDate = date),
                label: Text(title),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ..._cinemas.map(
          (cinema) => ExpansionTile(
            title: Text(cinema.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cinema.sessions
                    .map(
                      (session) => OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SeatSelectionScreen(sessionId: session.id),
                            ),
                          );
                        },
                        child: Text('${session.time} | ${session.price}тг'),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(title, style: const TextStyle(color: Color(0xFF9F9F9F))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabsHeaderDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: const Color(0xFF141414), child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class _ActorItem {
  const _ActorItem({required this.name});

  final String name;
}

class _ReviewItem {
  const _ReviewItem({
    required this.author,
    required this.date,
    required this.text,
    required this.rating,
  });

  final String author;
  final String date;
  final String text;
  final double rating;
}

class _CinemaItem {
  const _CinemaItem({required this.name, required this.sessions});

  final String name;
  final List<_SessionItem> sessions;
}

class _SessionItem {
  const _SessionItem({required this.id, required this.time, required this.price});

  final String id;
  final String time;
  final int price;
}
