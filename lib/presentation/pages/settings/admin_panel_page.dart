import 'dart:math' as math;

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
                                final rows = (data['rows'] as num?)?.toInt() ?? 12;
                                final cols = (data['cols'] as num?)?.toInt() ?? 12;
                                final layout = adminRepository.mapLayout(data['layout'] as List<dynamic>?, rows: rows, cols: cols);
                                final enabled = layout.where((e) => e.isEnabled).length;
                                final vip = layout.where((e) => e.isEnabled && e.isVip).length;

                                return ListTile(
                                  title: Text(data['name']?.toString() ?? hall.id),
                                  subtitle: Text('Размер: ${rows}x$cols • Обычные: ${enabled - vip} • VIP: $vip'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HallLayoutEditorPage(
                                          adminRepository: adminRepository,
                                          cinemaId: cinema.id,
                                          hallId: hall.id,
                                          hallName: data['name']?.toString() ?? hall.id,
                                          rows: rows,
                                          cols: cols,
                                          initialLayout: layout,
                                        ),
                                      ),
                                    );
                                  },
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый зал'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              await adminRepository.addHall(
                cinemaId: cinemaId,
                name: nameCtrl.text.trim(),
                rows: 12,
                cols: 12,
                vipRows: const [],
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
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Фильм'),
            items: _movies
                .map((movie) => DropdownMenuItem<MovieItem>(
                      value: movie,
                      child: Text(movie.title, overflow: TextOverflow.ellipsis, maxLines: 1),
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
                        final checked = selected.any((e) => e.hallId == option.ref.hallId && e.cinemaId == option.ref.cinemaId);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (value) {
                            setStateDialog(() {
                              if (value == true) {
                                selected.add(option.ref);
                              } else {
                                selected.removeWhere((e) => e.hallId == option.ref.hallId && e.cinemaId == option.ref.cinemaId);
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
        final rows = (data['rows'] as num?)?.toInt() ?? 12;
        final cols = (data['cols'] as num?)?.toInt() ?? 12;
        final layout = widget.adminRepository.mapLayout(data['layout'] as List<dynamic>?, rows: rows, cols: cols);

        result.add(
          _HallOption(
            label: '$cinemaName • ${data['name']} (${rows}x$cols)',
            ref: HallRef(
              cinemaId: cinema.id,
              cinemaName: cinemaName,
              cinemaAddress: address,
              hallId: hall.id,
              hallName: data['name']?.toString() ?? hall.id,
              rows: rows,
              cols: cols,
              vipRows: List<int>.from(data['vipRows'] as List<dynamic>? ?? const []),
              layout: layout,
            ),
          ),
        );
      }
    }
    return result;
  }
}

class HallLayoutEditorPage extends StatefulWidget {
  const HallLayoutEditorPage({
    super.key,
    required this.adminRepository,
    required this.cinemaId,
    required this.hallId,
    required this.hallName,
    required this.rows,
    required this.cols,
    required this.initialLayout,
  });

  final AdminRepository adminRepository;
  final String cinemaId;
  final String hallId;
  final String hallName;
  final int rows;
  final int cols;
  final List<SeatLayoutCell> initialLayout;

  @override
  State<HallLayoutEditorPage> createState() => _HallLayoutEditorPageState();
}

enum EditMode { enable, disable, vip }

class _HallLayoutEditorPageState extends State<HallLayoutEditorPage> {
  static const double _cellSize = 24;

  late int _rows;
  late int _cols;
  late List<SeatLayoutCell> _cells;
  EditMode _mode = EditMode.enable;
  Offset? _dragStart;
  Rect? _previewRect;

  @override
  void initState() {
    super.initState();
    _rows = widget.rows;
    _cols = widget.cols;
    _cells = List<SeatLayoutCell>.from(widget.initialLayout);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _cells.where((e) => e.isEnabled).length;
    final vip = _cells.where((e) => e.isEnabled && e.isVip).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Редактор: ${widget.hallName}'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Размер: ${_rows}x$_cols • Обычные: ${enabled - vip} • VIP: $vip'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ряды'),
                    IconButton(onPressed: () => _resize(rows: _rows - 1, cols: _cols), icon: const Icon(Icons.remove_circle_outline)),
                    Text('$_rows'),
                    IconButton(onPressed: () => _resize(rows: _rows + 1, cols: _cols), icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Места в ряду'),
                    IconButton(onPressed: () => _resize(rows: _rows, cols: _cols - 1), icon: const Icon(Icons.remove_circle_outline)),
                    Text('$_cols'),
                    IconButton(onPressed: () => _resize(rows: _rows, cols: _cols + 1), icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  selected: _mode == EditMode.enable,
                  label: const Text('Добавить места'),
                  onSelected: (_) => setState(() => _mode = EditMode.enable),
                ),
                ChoiceChip(
                  selected: _mode == EditMode.disable,
                  label: const Text('Убрать места'),
                  onSelected: (_) => setState(() => _mode = EditMode.disable),
                ),
                ChoiceChip(
                  selected: _mode == EditMode.vip,
                  label: const Text('Отметить VIP'),
                  onSelected: (_) => setState(() => _mode = EditMode.vip),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сброс 12x12'),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Зажмите и протяните по диагонали для выделения области'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Container(
                    child: SizedBox(
                      width: (_cols + 1) * _cellSize,
                      height: (_rows + 1) * _cellSize,
                      child: Column(
                        children: [
                          SizedBox(
                            height: _cellSize,
                            child: Row(
                              children: [
                                SizedBox(width: _cellSize),
                                ...List.generate(
                                  _cols,
                                  (index) => SizedBox(
                                    width: _cellSize,
                                    child: Center(
                                      child: Text('${index + 1}', style: const TextStyle(fontSize: 10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: _cellSize,
                                  child: Column(
                                    children: List.generate(
                                      _rows,
                                      (index) => SizedBox(
                                        height: _cellSize,
                                        child: Center(
                                          child: Text('${index + 1}', style: const TextStyle(fontSize: 10)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onPanStart: (d) => _onDragStart(d.localPosition),
                                  onPanUpdate: (d) => _onDragUpdate(d.localPosition),
                                  onPanEnd: (_) => _applyRect(),
                                  child: SizedBox(
                                    width: _cols * _cellSize,
                                    height: _rows * _cellSize,
                                    child: Stack(
                                      children: [
                                        GridView.builder(
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: _rows * _cols,
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: _cols,
                                            mainAxisSpacing: 0,
                                            crossAxisSpacing: 0,
                                          ),
                                          itemBuilder: (context, index) {
                                            final cell = _cells[index];
                                            Color color;
                                            if (!cell.isEnabled) {
                                              color = Colors.grey.shade300;
                                            } else if (cell.isVip) {
                                              color = Colors.amber;
                                            } else {
                                              color = Colors.redAccent;
                                            }

                                            return Container(
                                              margin: const EdgeInsets.all(1),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            );
                                          },
                                        ),
                                        if (_previewRect != null)
                                          Positioned.fromRect(
                                            rect: _previewRect!,
                                            child: IgnorePointer(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.blueAccent, width: 2),
                                                  color: Colors.blueAccent.withOpacity(0.15),
                                                ),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _resize({required int rows, required int cols}) {
    final safeRows = rows.clamp(4, 30);
    final safeCols = cols.clamp(4, 30);

    if (safeRows == _rows && safeCols == _cols) return;

    final map = <String, SeatLayoutCell>{
      for (final cell in _cells) '${cell.row}_${cell.col}': cell,
    };

    final resized = <SeatLayoutCell>[];
    for (int r = 1; r <= safeRows; r++) {
      for (int c = 1; c <= safeCols; c++) {
        final key = '${r}_${c}';
        final old = map[key];
        resized.add(
          old ?? SeatLayoutCell(row: r, col: c, isEnabled: false, isVip: false),
        );
      }
    }

    setState(() {
      _rows = safeRows;
      _cols = safeCols;
      _cells = resized;
    });
  }

  void _reset() {
    setState(() {
      _rows = 12;
      _cols = 12;
      _cells = List.generate(
        _rows * _cols,
        (index) => SeatLayoutCell(
          row: index ~/ _cols + 1,
          col: index % _cols + 1,
          isEnabled: false,
          isVip: false,
        ),
      );
      _previewRect = null;
      _dragStart = null;
    });
  }

  void _onDragStart(Offset local) {
    setState(() {
      _dragStart = local;
      _previewRect = Rect.fromPoints(local, local);
    });
  }

  void _onDragUpdate(Offset local) {
    if (_dragStart == null) return;
    setState(() {
      _previewRect = Rect.fromPoints(_dragStart!, local);
    });
  }

  void _applyRect() {
    if (_previewRect == null || _dragStart == null) return;

    final left = (_previewRect!.left / _cellSize).floor().clamp(0, _cols - 1);
    final right = (_previewRect!.right / _cellSize).floor().clamp(0, _cols - 1);
    final top = (_previewRect!.top / _cellSize).floor().clamp(0, _rows - 1);
    final bottom = (_previewRect!.bottom / _cellSize).floor().clamp(0, _rows - 1);

    final minRow = math.min(top, bottom) + 1;
    final maxRow = math.max(top, bottom) + 1;
    final minCol = math.min(left, right) + 1;
    final maxCol = math.max(left, right) + 1;

    setState(() {
      _cells = _cells.map((cell) {
        final inRect = cell.row >= minRow && cell.row <= maxRow && cell.col >= minCol && cell.col <= maxCol;
        if (!inRect) return cell;

        switch (_mode) {
          case EditMode.enable:
            return cell.copyWith(isEnabled: true, isVip: false);
          case EditMode.disable:
            return cell.copyWith(isEnabled: false, isVip: false);
          case EditMode.vip:
            return cell.isEnabled ? cell.copyWith(isVip: !cell.isVip) : cell;
        }
      }).toList();
      _previewRect = null;
      _dragStart = null;
    });
  }

  Future<void> _save() async {
    await widget.adminRepository.updateHallLayout(
      cinemaId: widget.cinemaId,
      hallId: widget.hallId,
      rows: _rows,
      cols: _cols,
      layout: _cells.map((e) => e.toMap()).toList(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Макет зала сохранен')));
    Navigator.pop(context);
  }
}

class _HallOption {
  const _HallOption({required this.label, required this.ref});

  final String label;
  final HallRef ref;
}
