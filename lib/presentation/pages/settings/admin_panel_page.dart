import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/schedule_cells_service.dart';
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
  final ScheduleCellsService _cellsService = ScheduleCellsService();
  final TextEditingController _adultPriceController = TextEditingController(text: '2500');
  final TextEditingController _studentPriceController = TextEditingController(text: '1800');
  final TextEditingController _childPriceController = TextEditingController(text: '1200');
  final TextEditingController _vipPriceController = TextEditingController(text: '5000');

  MovieItem? _selectedMovie;
  MovieMeta? _movieMeta;

  DateTime _selectedDate = DateTime.now();
  int _dateOffset = 0;
  List<MovieItem> _movies = const [];
  List<_HallOption> _halls = const [];
  List<ScheduleCellItem> _grid = const [];

  bool _loading = true;
  bool _saving = false;
  String? _selectedCellId;
  Set<String> _conflictCellIds = <String>{};
  final List<List<ScheduleCellItem>> _undoStack = <List<ScheduleCellItem>>[];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _adultPriceController.dispose();
    _studentPriceController.dispose();
    _childPriceController.dispose();
    _vipPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    final movies = await widget.adminRepository.loadMovies();
    final halls = await _loadHallOptions(await FirebaseFirestore.instance.collection('cinemas').get());
    await _cellsService.ensureGrid(date: _selectedDate, halls: halls.map((e) => e.ref).toList());
    final grid = await _cellsService.loadGrid(_selectedDate);

    if (!mounted) return;
    setState(() {
      _movies = movies;
      _halls = halls;
      _grid = grid;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final duration = _movieMeta?.durationMinutes ?? _parseDuration(_selectedMovie?.duration ?? '2ч 0м');
    final age = _movieMeta?.ageRating ?? '16+';

    final grouped = <String, List<ScheduleCellItem>>{};
    for (final cell in _grid) {
      final key = '${cell.cinemaName}__${cell.hallName}__${cell.cinemaId}__${cell.hallId}';
      grouped.putIfAbsent(key, () => []).add(cell);
    }
    for (final entry in grouped.values) {
      entry.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
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
            items: _movies.map((movie) => DropdownMenuItem<MovieItem>(
              value: movie,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 28,
                      height: 42,
                      child: movie.imageUrl.isEmpty
                          ? Container(color: Colors.grey.shade300)
                          : Image.network(movie.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(movie.title, overflow: TextOverflow.ellipsis)),
                ],
              ),
            )).toList(),
            onChanged: (value) async {
              if (value == null) return;
              setState(() => _selectedMovie = value);
              final meta = await widget.adminRepository.loadMovieMeta(value.id, value.duration);
              if (!mounted) return;
              setState(() => _movieMeta = meta);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _dateOffset,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Дата'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Сегодня')),
              DropdownMenuItem(value: 1, child: Text('Завтра')),
              DropdownMenuItem(value: 2, child: Text('Послезавтра')),
            ],
            onChanged: (offset) async {
              if (offset == null) return;
              final base = DateTime.now();
              final nextDate = DateTime(base.year, base.month, base.day).add(Duration(days: offset));
              setState(() {
                _dateOffset = offset;
                _selectedDate = nextDate;
                _loading = true;
                _selectedCellId = null;
                _conflictCellIds = <String>{};
              });
              await _cellsService.ensureGrid(date: nextDate, halls: _halls.map((e) => e.ref).toList());
              final grid = await _cellsService.loadGrid(nextDate);
              if (!mounted) return;
              setState(() {
                _grid = grid;
                _loading = false;
              });
            },
          ),
          const SizedBox(height: 8),
          if (_selectedMovie != null)
            Text('Возраст: $age • Длительность: ${duration} мин', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Цены: Взр ${_adultPriceController.text} ₸ • Студ ${_studentPriceController.text} ₸ • Дет ${_childPriceController.text} ₸ • VIP ${_vipPriceController.text} ₸',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton.icon(
                onPressed: _openPricesDialog,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Изменить цены'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: grouped.entries.map((entry) {
                final parts = entry.key.split('__');
                final cinemaName = parts[0];
                final hallName = parts[1];
                final hallCells = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('$cinemaName • $hallName', style: const TextStyle(fontWeight: FontWeight.w600))),
                            IconButton(
                              onPressed: () => _addSlotForHall(hallCells),
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Добавить ячейку',
                            ),
                            IconButton(
                              onPressed: () => _removeSlotForHall(hallCells),
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: 'Удалить ячейку',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: hallCells.map((cell) {
                            final state = _cellState(cell);
                            final isSelected = _selectedCellId == cell.id;
                            final hasConflict = _conflictCellIds.contains(cell.id);
                            return GestureDetector(
                              onTap: _selectedMovie == null ? null : () => _onCellTap(cell, hallCells, duration),
                              child: Container(
                                width: 110,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: state.color,
                                  border: Border.all(color: isSelected ? Colors.blue : state.border, width: isSelected ? 2 : 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatTime(cell.startTime), style: TextStyle(fontWeight: FontWeight.w600, color: hasConflict ? Colors.red : state.textColor)),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasConflict ? 'Конфликт' : (cell.movieTitle ?? 'Свободно'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: hasConflict ? Colors.red : state.textColor),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _resetSessionsForDate,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Обнулить сеансы'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _undoStack.isEmpty ? null : _undo,
                icon: const Icon(Icons.undo),
                label: const Text('Отменить'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _selectedMovie == null || _saving || _conflictCellIds.isNotEmpty ? null : _saveAll,
                  icon: const Icon(Icons.save),
                  label: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _CellState _cellState(ScheduleCellItem cell) {
    if (cell.movieId == null) return _CellState(Colors.grey.shade300, Colors.grey.shade500, Colors.black);
    if (_selectedMovie != null && cell.movieId == _selectedMovie!.id) {
      return _CellState(Colors.green.withOpacity(0.25), Colors.green, Colors.black);
    }
    return _CellState(Colors.red.withOpacity(0.25), Colors.red, Colors.red.shade900);
  }

  Future<void> _onCellTap(ScheduleCellItem pivot, List<ScheduleCellItem> hallCells, int duration) async {
    if (_selectedMovie == null) return;

    setState(() {
      _selectedCellId = pivot.id;
      _conflictCellIds = <String>{};
    });

    if (pivot.movieId != null && pivot.movieId != _selectedMovie!.id) {
      setState(() => _conflictCellIds = {pivot.id});
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(pivot.startTime),
    );
    if (picked == null) return;

    final newTime = _roundTo10(
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, picked.hour, picked.minute),
    );

    final snapshot = _grid.map((e) => e).toList();
    _undoStack.add(snapshot);

    final updated = pivot.copyWith(
      startTime: newTime,
      movieId: _selectedMovie!.id,
      movieTitle: _selectedMovie!.title,
    );

    final conflicts = <String>{};
    final otherCells = hallCells.where((e) => e.id != pivot.id);
    for (final other in otherCells) {
      if (other.movieId != null && other.movieId != _selectedMovie!.id && other.startTime.isAtSameMomentAs(newTime)) {
        conflicts.add(pivot.id);
        break;
      }
    }

    setState(() {
      _grid = _grid.map((cell) => cell.id == updated.id ? updated : cell).toList();
      _conflictCellIds = conflicts;
    });
  }

  Future<void> _addSlotForHall(List<ScheduleCellItem> hallCells) async {
    if (hallCells.isEmpty) return;
    final first = hallCells.first;
    final hall = _halls.firstWhere((h) => h.ref.cinemaId == first.cinemaId && h.ref.hallId == first.hallId).ref;
    await _cellsService.addSlotForHall(date: _selectedDate, hall: hall);
    final reloaded = await _cellsService.loadGrid(_selectedDate);
    if (!mounted) return;
    setState(() => _grid = reloaded);
  }


  Future<void> _removeSlotForHall(List<ScheduleCellItem> hallCells) async {
    if (hallCells.isEmpty) return;
    final first = hallCells.first;
    final hall = _halls.firstWhere((h) => h.ref.cinemaId == first.cinemaId && h.ref.hallId == first.hallId).ref;
    final snapshot = _grid.map((e) => e).toList();
    _undoStack.add(snapshot);
    await _cellsService.removeLastSlotForHall(date: _selectedDate, hall: hall);
    final reloaded = await _cellsService.loadGrid(_selectedDate);
    if (!mounted) return;
    setState(() => _grid = reloaded);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    setState(() {
      _grid = previous;
      _conflictCellIds = <String>{};
      _selectedCellId = null;
    });
  }

  Future<void> _saveAll() async {
    if (_selectedMovie == null) return;
    setState(() => _saving = true);

    await _cellsService.saveGrid(_grid);
    await widget.adminRepository.clearMovieScheduleForDate(
      movieId: _selectedMovie!.id,
      date: _selectedDate,
    );

    final selectedCells = _grid.where((c) => c.movieId == _selectedMovie!.id).toList();
    final byHall = <String, List<ScheduleCellItem>>{};
    for (final c in selectedCells) {
      final key = '${c.cinemaId}_${c.hallId}';
      byHall.putIfAbsent(key, () => []).add(c);
    }

    for (final hallEntry in byHall.entries) {
      final first = hallEntry.value.first;
      final hallRef = _halls.firstWhere((h) => h.ref.cinemaId == first.cinemaId && h.ref.hallId == first.hallId).ref;
      await widget.adminRepository.saveMovieScheduleForHall(
        movie: _selectedMovie!,
        hall: hallRef,
        starts: hallEntry.value.map((e) => e.startTime).toList(),
        prices: _readPrices(),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Расписание сохранено')));
  }

  Future<void> _resetSessionsForDate() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обнулить сеансы?'),
        content: const Text('Все сеансы на выбранную дату будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Обнулить')),
        ],
      ),
    );

    if (shouldReset != true) return;
    setState(() => _saving = true);

    final snapshot = _grid.map((e) => e).toList();
    _undoStack.add(snapshot);

    final movieIds = _grid
        .where((cell) => cell.movieId != null)
        .map((cell) => cell.movieId!)
        .toSet();

    for (final movieId in movieIds) {
      await widget.adminRepository.clearMovieScheduleForDate(
        movieId: movieId,
        date: _selectedDate,
      );
    }

    final clearedGrid = _grid
        .map((cell) => cell.copyWith(movieId: null, movieTitle: null))
        .toList();

    await _cellsService.saveGrid(clearedGrid);

    if (!mounted) return;
    setState(() {
      _grid = clearedGrid;
      _saving = false;
      _selectedCellId = null;
      _conflictCellIds = <String>{};
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сеансы обнулены')));
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

  DateTime _roundTo10(DateTime value) {
    final minute = value.minute;
    final rounded = (minute / 10).round() * 10;
    return DateTime(value.year, value.month, value.day, value.hour, 0).add(Duration(minutes: rounded));
  }

  String _formatTime(DateTime date) => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Widget _buildPriceField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '$label (₸)',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  SessionPrices _readPrices() {
    int parse(TextEditingController controller, int fallback) {
      final value = int.tryParse(controller.text.trim());
      if (value == null || value <= 0) return fallback;
      return value;
    }

    return SessionPrices(
      adult: parse(_adultPriceController, 2500),
      student: parse(_studentPriceController, 1800),
      child: parse(_childPriceController, 1200),
      vip: parse(_vipPriceController, 5000),
    );
  }

  Future<void> _openPricesDialog() async {
    final adultController = TextEditingController(text: _adultPriceController.text);
    final studentController = TextEditingController(text: _studentPriceController.text);
    final childController = TextEditingController(text: _childPriceController.text);
    final vipController = TextEditingController(text: _vipPriceController.text);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить цены билетов'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPriceField(adultController, 'Взрослый'),
              const SizedBox(height: 8),
              _buildPriceField(studentController, 'Студенческий'),
              const SizedBox(height: 8),
              _buildPriceField(childController, 'Детский'),
              const SizedBox(height: 8),
              _buildPriceField(vipController, 'VIP'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (saved == true) {
      setState(() {
        _adultPriceController.text = adultController.text;
        _studentPriceController.text = studentController.text;
        _childPriceController.text = childController.text;
        _vipPriceController.text = vipController.text;
      });
    }
    adultController.dispose();
    studentController.dispose();
    childController.dispose();
    vipController.dispose();
  }

  int _parseDuration(String durationStr) {
    final hoursMatch = RegExp(r'(\d+)ч').firstMatch(durationStr);
    final minsMatch = RegExp(r'(\d+)м').firstMatch(durationStr);
    int total = 0;
    if (hoursMatch != null) total += int.parse(hoursMatch.group(1)!) * 60;
    if (minsMatch != null) total += int.parse(minsMatch.group(1)!);
    return total > 0 ? total : 120;
  }
}

class _CellState {
  const _CellState(this.color, this.border, this.textColor);

  final Color color;
  final Color border;
  final Color textColor;
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
