import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'checkout_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({
    super.key,
    required this.sessionId,
    required this.movieTitle,
    required this.hallName,
    required this.sessionTime,
  });

  final String sessionId;
  final String movieTitle;
  final String hallName;
  final String sessionTime;

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _rows = 10;
  int _seatsPerRow = 10;
  bool _hasVipConfig = false;
  Set<String> _vipSeatNumbers = <String>{};
  bool _isLoading = true;

  final Map<TicketSeat, TicketTariff> _selectedSeats = <TicketSeat, TicketTariff>{};
  Set<TicketSeat> _occupiedSeats = <TicketSeat>{};

  TicketSeat? _focusedSeat;
  TicketTariff _activeTariff = TicketTariff.adult;
  _BottomPanelMode _bottomPanelMode = _BottomPanelMode.hidden;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    try {
      final sessionSnapshot =
          await _firestore.collection('sessions').doc(widget.sessionId).get();
      if (!sessionSnapshot.exists) {
        throw StateError('Сеанс не найден');
      }

      final sessionData = sessionSnapshot.data()!;
      final List<dynamic> bookedDynamic =
          sessionData['booked_seats'] as List<dynamic>? ?? <dynamic>[];

      final hallId = sessionData['hall_id'] as String?;
      if (hallId != null) {
        final hallSnapshot = await _firestore.collection('halls').doc(hallId).get();
        if (hallSnapshot.exists) {
          final hallData = hallSnapshot.data()!;
          _rows = (hallData['rows_count'] as num?)?.toInt() ?? _rows;
          _seatsPerRow = (hallData['seats_per_row'] as num?)?.toInt() ?? _seatsPerRow;

          final vipDynamic = hallData['vip_seats'] as List<dynamic>?;
          if (vipDynamic != null && vipDynamic.isNotEmpty) {
            _vipSeatNumbers = vipDynamic.map((seat) => seat.toString()).toSet();
            _hasVipConfig = true;
          }
        }
      }

      _occupiedSeats = bookedDynamic
          .map((value) => TicketSeat.fromSeatNumber(value.toString()))
          .whereType<TicketSeat>()
          .toSet();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки мест: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isVip(TicketSeat seat) {
    if (_hasVipConfig) {
      return _vipSeatNumbers.contains(seat.seatNumber);
    }
    return seat.row >= _rows - 1;
  }

  int _basePrice(TicketSeat seat) => _isVip(seat) ? 5000 : 2500;

  int _priceFor(TicketSeat seat, TicketTariff tariff) {
    final base = _basePrice(seat);
    return switch (tariff) {
      TicketTariff.adult => base,
      TicketTariff.child => (base * 0.7).round(),
      TicketTariff.student => (base * 0.85).round(),
    };
  }

  int get _totalPrice => _selectedSeats.entries.fold<int>(
        0,
        (sum, item) => sum + _priceFor(item.key, item.value),
      );

  void _focusSeat(TicketSeat seat) {
    if (_occupiedSeats.contains(seat)) {
      return;
    }
    setState(() {
      _focusedSeat = seat;
      _activeTariff = _selectedSeats[seat] ?? TicketTariff.adult;
      _bottomPanelMode = _BottomPanelMode.seatInfo;
    });
  }

  void _addFocusedSeat() {
    final focused = _focusedSeat;
    if (focused == null) {
      return;
    }
    setState(() {
      _selectedSeats[focused] = _activeTariff;
      _bottomPanelMode = _BottomPanelMode.cart;
    });
  }

  void _removeSeat(TicketSeat seat) {
    setState(() {
      _selectedSeats.remove(seat);
      if (_selectedSeats.isEmpty) {
        _bottomPanelMode =
            _focusedSeat == null ? _BottomPanelMode.hidden : _BottomPanelMode.seatInfo;
      }
    });
  }

  void _goToCheckout() {
    if (_selectedSeats.isEmpty) {
      return;
    }
    final sortedSeats = _selectedSeats.entries.toList()
      ..sort(
        (a, b) => a.key.row != b.key.row
            ? a.key.row.compareTo(b.key.row)
            : a.key.seat.compareTo(b.key.seat),
      );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          sessionId: widget.sessionId,
          movieTitle: widget.movieTitle,
          hallName: widget.hallName,
          sessionTime: widget.sessionTime,
          seats: sortedSeats
              .map(
                (entry) => CheckoutSeatLine(
                  row: entry.key.row,
                  seat: entry.key.seat,
                  seatNumber: entry.key.seatNumber,
                  tariff: entry.value.label,
                  price: _priceFor(entry.key, entry.value),
                ),
              )
              .toList(),
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final hasBottomPanel = _bottomPanelMode != _BottomPanelMode.hidden;
    final bottomOffset = hasBottomPanel ? 210 + bottomInset : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор мест'), centerTitle: true),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, bottomOffset),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 2.8,
              boundaryMargin: const EdgeInsets.all(100),
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ScreenArc(),
                      const SizedBox(height: 28),
                      ...List.generate(_rows, (rowIndex) {
                        final row = rowIndex + 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_seatsPerRow, (seatIndex) {
                              final seat = TicketSeat(row: row, seat: seatIndex + 1);
                              return _SeatWidget(
                                seat: seat,
                                isOccupied: _occupiedSeats.contains(seat),
                                isSelected: _selectedSeats.containsKey(seat),
                                isVip: _isVip(seat),
                                onTap: () => _focusSeat(seat),
                              );
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasBottomPanel)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + bottomInset),
                decoration: const BoxDecoration(
                  color: Color(0xFF151515),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, -5)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _bottomPanelMode == _BottomPanelMode.seatInfo
                        ? _buildSeatInfoPanel()
                        : _buildCartPanel(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeatInfoPanel() {
    final seat = _focusedSeat;
    if (seat == null) {
      return const SizedBox.shrink();
    }
    final isAdded = _selectedSeats.containsKey(seat);
    return Column(
      key: const ValueKey('seat-info-panel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ряд ${seat.row}, Место ${seat.seat} (${seat.seatNumber})',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          'Тариф',
          style: TextStyle(color: Color(0xFFB7B7B7), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TicketTariff.values.map((tariff) {
            return ChoiceChip(
              selected: _activeTariff == tariff,
              label: Text('${tariff.label} • ${_priceFor(seat, tariff)} ₸'),
              onSelected: (_) => setState(() => _activeTariff = tariff),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addFocusedSeat,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(isAdded ? 'Обновить' : 'Добавить'),
          ),
        ),
        if (_selectedSeats.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _bottomPanelMode = _BottomPanelMode.cart),
            child: Text('Перейти в корзину (${_selectedSeats.length})'),
          ),
        ],
      ],
    );
  }

  Widget _buildCartPanel() {
    return Column(
      key: const ValueKey('cart-panel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedSeats.length} билет(ов) • $_totalPrice ₸',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _selectedSeats.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Chip(
                  backgroundColor: const Color(0xFF262626),
                  label: Text('${entry.key.seatNumber} (${entry.value.short})'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeSeat(entry.key),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _goToCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Купить билеты'),
          ),
        ),
      ],
    );
  }
}

class _ScreenArc extends StatelessWidget {
  const _ScreenArc();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 86,
      child: CustomPaint(
        painter: _ScreenPainter(),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'Экран',
              style: TextStyle(
                color: Color(0xFF102844),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 4, size.width, size.height - 14);
    final gradient = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFF8EC5FF)]);
    final paint = Paint()..shader = gradient.createShader(rect);

    final path = Path()
      ..moveTo(8, 18)
      ..quadraticBezierTo(size.width / 2, 2, size.width - 8, 18)
      ..quadraticBezierTo(size.width - 18, size.height - 6, size.width / 2, size.height)
      ..quadraticBezierTo(18, size.height - 6, 8, 18)
      ..close();

    canvas.drawShadow(path, const Color(0x668EC5FF), 16, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeatWidget extends StatelessWidget {
  const _SeatWidget({
    required this.seat,
    required this.isOccupied,
    required this.isSelected,
    required this.isVip,
    required this.onTap,
  });

  final TicketSeat seat;
  final bool isOccupied;
  final bool isSelected;
  final bool isVip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFF5A5A5A);
    Color fillColor = Colors.transparent;

    if (isVip) {
      borderColor = const Color(0xFFFFC85A);
    }
    if (isOccupied) {
      borderColor = const Color(0xFFA4A4A4);
      fillColor = const Color(0xFFA4A4A4);
    }
    if (isSelected) {
      borderColor = const Color(0xFFE53935);
      fillColor = const Color(0xFFE53935);
    }

    return GestureDetector(
      onTap: isOccupied ? null : onTap,
      child: Container(
        width: 30,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '${seat.seat}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected || isOccupied ? Colors.black : const Color(0xFFCFCFCF),
          ),
        ),
      ),
    );
  }
}

class TicketSeat {
  const TicketSeat({required this.row, required this.seat});

  final int row;
  final int seat;

  String get seatNumber {
    final rowLetter = String.fromCharCode(64 + row);
    return '$rowLetter$seat';
  }

  static TicketSeat? fromSeatNumber(String value) {
    if (value.isEmpty) {
      return null;
    }

    final rowLetter = value[0].toUpperCase();
    final seatPart = value.substring(1);
    final row = rowLetter.codeUnitAt(0) - 64;
    final seat = int.tryParse(seatPart);

    if (row <= 0 || seat == null || seat <= 0) {
      return null;
    }

    return TicketSeat(row: row, seat: seat);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketSeat && other.row == row && other.seat == seat;
  }

  @override
  int get hashCode => Object.hash(row, seat);
}

enum TicketTariff {
  adult('Взрослый', 'ВЗР'),
  child('Детский', 'ДЕТ'),
  student('Студенческий', 'СТУ');

  const TicketTariff(this.label, this.short);

  final String label;
  final String short;
}

enum _BottomPanelMode { hidden, seatInfo, cart }
