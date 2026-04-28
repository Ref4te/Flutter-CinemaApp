import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/admin_repository.dart';
import '../../../domain/entities/movie.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final AdminRepository _adminRepository = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Панель администратора'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Кинотеатры и залы'),
              Tab(text: 'Расписание'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CinemaManagementTab(adminRepository: _adminRepository),
            _ScheduleManagementTab(adminRepository: _adminRepository),
          ],
        ),
      ),
    );
  }
}

class _CinemaManagementTab extends StatelessWidget {
  const _CinemaManagementTab({required this.adminRepository});

  final AdminRepository adminRepository;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showAddCinemaDialog(context),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Добавить кинотеатр'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: adminRepository.cinemasStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final cinemas = snapshot.data?.docs ?? [];
              if (cinemas.isEmpty) {
                return const Center(child: Text('Пока нет кинотеатров'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cinemas.length,
                itemBuilder: (context, index) {
                  final cinema = cinemas[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(cinema.data()['name']?.toString() ?? 'Без названия'),
                      subtitle: Text(cinema.data()['address']?.toString() ?? 'Без адреса'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => adminRepository.deleteCinema(cinema.id),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _showAddHallDialog(context, cinema.id),
                              icon: const Icon(Icons.add),
                              label: const Text('Добавить зал'),
                            ),
                          ),
                        ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: adminRepository.hallsStream(cinema.id),
                          builder: (context, hallSnapshot) {
                            final halls = hallSnapshot.data?.docs ?? [];
                            if (halls.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text('Нет залов'),
                              );
                            }

                            return Column(
                              children: halls.map((hall) {
                                final data = hall.data();
                                final rows = (data['rows'] as num?)?.toInt() ?? 0;
                                final cols = (data['cols'] as num?)?.toInt() ?? 0;
                                final vipRows = List<int>.from(data['vipRows'] as List<dynamic>? ?? const []);
                                return ListTile(
                                  title: Text(data['name']?.toString() ?? hall.id),
                                  subtitle: Text('Размер: ${rows}x$cols  • VIP ряды: ${vipRows.join(', ')}'),
                                  onTap: () => _showHallLayout(context, data),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => adminRepository.deleteHall(cinemaId: cinema.id, hallId: hall.id),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showHallLayout(BuildContext context, Map<String, dynamic> hallData) {
    final rows = (hallData['rows'] as num?)?.toInt() ?? 0;
    final cols = (hallData['cols'] as num?)?.toInt() ?? 0;
    final vipRows = List<int>.from(hallData['vipRows'] as List<dynamic>? ?? const []);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(hallData['name']?.toString() ?? 'Зал'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Размер: ${rows}x$cols'),
                const SizedBox(height: 8),
                Text('Обычные места: ${(rows * cols) - (vipRows.length * cols)}'),
                Text('VIP места: ${vipRows.length * cols}'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(rows, (r) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(cols, (c) {
                              final isVip = vipRows.contains(r + 1);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isVip ? Colors.amber : Colors.redAccent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCinemaDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый кинотеатр'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Адрес'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await adminRepository.createCinema(
                name: nameCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showAddHallDialog(BuildContext context, String cinemaId) {
    final nameCtrl = TextEditingController(text: 'Зал');
    final rowsCtrl = TextEditingController(text: '7');
    final colsCtrl = TextEditingController(text: '10');
    final vipRowsCtrl = TextEditingController(text: '5,6');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый зал'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: rowsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ряды')),
            TextField(controller: colsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Мест в ряду')),
            TextField(controller: vipRowsCtrl, decoration: const InputDecoration(labelText: 'VIP ряды (через запятую)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final rows = int.tryParse(rowsCtrl.text.trim()) ?? 7;
              final cols = int.tryParse(colsCtrl.text.trim()) ?? 10;
              final vipRows = vipRowsCtrl.text
                  .split(',')
                  .map((e) => int.tryParse(e.trim()))
                  .whereType<int>()
                  .toList();
              await adminRepository.addHall(
                cinemaId: cinemaId,
                name: nameCtrl.text.trim(),
                rows: rows,
                cols: cols,
                vipRows: vipRows,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleManagementTab extends StatefulWidget {
  const _ScheduleManagementTab({required this.adminRepository});

  final AdminRepository adminRepository;

  @override
  State<_ScheduleManagementTab> createState() => _ScheduleManagementTabState();
}

class _ScheduleManagementTabState extends State<_ScheduleManagementTab> {
  MovieItem? _selectedMovie;
  int? _selectedHour;
  List<MovieItem> _movies = const [];
  bool _loadingMovies = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() => _loadingMovies = true);
    final movies = await widget.adminRepository.loadMovies();
    if (!mounted) return;
    setState(() {
      _movies = movies;
      _loadingMovies = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMovies) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<MovieItem>(
            value: _selectedMovie,
            decoration: const InputDecoration(labelText: 'Фильм'),
            items: _movies
                .map((movie) => DropdownMenuItem<MovieItem>(
                      value: movie,
                      child: Text(movie.title, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedMovie = value),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [10, 11, 12].map((hour) {
              final selected = _selectedHour == hour;
              return ChoiceChip(
                label: Text('${hour.toString().padLeft(2, '0')}:00'),
                selected: selected,
                onSelected: (_) => setState(() => _selectedHour = hour),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _selectedMovie == null || _selectedHour == null
                      ? null
                      : () async {
                          await _showHallSelectorAndApply();
                        },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Применить расписание'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _selectedMovie == null
                    ? null
                    : () => widget.adminRepository.clearMovieSchedule(_selectedMovie!.id),
                child: const Text('Очистить'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedMovie != null)
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.adminRepository.movieScheduleStream(_selectedMovie!.id),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('Для этого фильма пока нет сеансов в расписании'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final start = (data['startTime'] as Timestamp).toDate();
                      final end = (data['endTime'] as Timestamp).toDate();
                      return Card(
                        child: ListTile(
                          title: Text('${data['cinemaName']} • ${data['hallName']}'),
                          subtitle: Text(
                            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} '
                            '- ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showHallSelectorAndApply() async {
    final cinemasSnapshot = await FirebaseFirestore.instance.collection('cinemas').get();
    final selected = <HallRef>[];

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Выберите залы'),
              content: SizedBox(
                width: 360,
                child: FutureBuilder<List<_HallOption>>(
                  future: _loadHallOptions(cinemasSnapshot),
                  builder: (context, snapshot) {
                    final options = snapshot.data ?? [];
                    return ListView(
                      shrinkWrap: true,
                      children: options.map((option) {
                        final checked = selected.any((e) => e.hallId == option.ref.hallId);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (value) {
                            setStateDialog(() {
                              if (value == true) {
                                selected.add(option.ref);
                              } else {
                                selected.removeWhere((e) => e.hallId == option.ref.hallId);
                              }
                            });
                          },
                          title: Text(option.label),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          await widget.adminRepository.clearMovieSchedule(_selectedMovie!.id);
                          await widget.adminRepository.applyScheduleForMovie(
                            movie: _selectedMovie!,
                            halls: selected,
                            baseHour: _selectedHour!,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<_HallOption>> _loadHallOptions(QuerySnapshot<Map<String, dynamic>> cinemasSnapshot) async {
    final result = <_HallOption>[];
    for (final cinema in cinemasSnapshot.docs) {
      final cinemaName = cinema.data()['name']?.toString() ?? 'Кинотеатр';
      final address = cinema.data()['address']?.toString() ?? '';
      final halls = await cinema.reference.collection('halls').get();

      for (final hall in halls.docs) {
        final data = hall.data();
        result.add(
          _HallOption(
            label: '$cinemaName • ${data['name']} (${data['rows']}x${data['cols']})',
            ref: HallRef(
              cinemaId: cinema.id,
              cinemaName: cinemaName,
              cinemaAddress: address,
              hallId: hall.id,
              hallName: data['name']?.toString() ?? hall.id,
              rows: (data['rows'] as num?)?.toInt() ?? 7,
              cols: (data['cols'] as num?)?.toInt() ?? 10,
              vipRows: List<int>.from(data['vipRows'] as List<dynamic>? ?? const []),
            ),
          ),
        );
      }
    }
    return result;
  }
}

class _HallOption {
  const _HallOption({required this.label, required this.ref});

  final String label;
  final HallRef ref;
}
