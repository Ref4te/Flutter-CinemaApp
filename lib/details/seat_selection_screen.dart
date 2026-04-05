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
  static const int _rows = 10;
  static const int _seatsPerRow = 10;
  static const int _standardPrice = 2500;
  static const int _vipPrice = 5000;

  final Map<TicketSeat, TicketTariff> _selectedSeats = <TicketSeat, TicketTariff>{};
  late final Set<TicketSeat> _occupiedSeats;

  TicketSeat? _focusedSeat;
  TicketTariff _activeTariff = TicketTariff.adult;

  @override
  void initState() {
    super.initState();
    _occupiedSeats = {
      const TicketSeat(row: 1, seat: 3),
      const TicketSeat(row: 1, seat: 4),
      const TicketSeat(row: 2, seat: 7),
      const TicketSeat(row: 4, seat: 2),
      const TicketSeat(row: 5, seat: 5),
      const TicketSeat(row: 8, seat: 9),
      const TicketSeat(row: 9, seat: 1),
      const TicketSeat(row: 10, seat: 6),
    };
  }

  bool _isVip(TicketSeat seat) => seat.row >= _rows - 1;

  int _basePrice(TicketSeat seat) => _isVip(seat) ? _vipPrice : _standardPrice;

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
    });
  }

  void _addFocusedSeat() {
    final focused = _focusedSeat;
    if (focused == null) {
      return;
    }
    setState(() {
      _selectedSeats[focused] = _activeTariff;
    });
  }

  void _removeSeat(TicketSeat seat) {
    setState(() {
      _selectedSeats.remove(seat);
      if (_focusedSeat == seat) {
        _focusedSeat = null;
      }
    });
  }

  void _goToCheckout() {
    if (_selectedSeats.isEmpty) {
      return;
    }
    final sortedSeats = _selectedSeats.entries.toList()
      ..sort(
        (a, b) =>
            a.key.row != b.key.row ? a.key.row.compareTo(b.key.row) : a.key.seat.compareTo(b.key.seat),
      );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          movieTitle: widget.movieTitle,
          hallName: widget.hallName,
          sessionTime: widget.sessionTime,
          seats: sortedSeats
              .map(
                (entry) => CheckoutSeatLine(
                  row: entry.key.row,
                  seat: entry.key.seat,
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final cartOffset = _selectedSeats.isEmpty ? 0.0 : 140 + bottomInset;

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор мест'), centerTitle: true),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, cartOffset),
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
          if (_focusedSeat != null)
            DraggableScrollableSheet(
              initialChildSize: 0.22,
              minChildSize: 0.16,
              maxChildSize: 0.45,
              builder: (context, controller) {
                final seat = _focusedSeat!;
                final isAdded = _selectedSeats.containsKey(seat);
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(16, 14, 16, cartOffset > 0 ? 86 + bottomInset : 18),
                    children: [
                      Center(
                        child: Container(
                          width: 56,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4C4C4C),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ряд ${seat.row}, Место ${seat.seat}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
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
                            onSelected: (_) {
                              setState(() => _activeTariff = tariff);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
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
                    ],
                  ),
                );
              },
            ),
          if (_selectedSeats.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottomInset),
                decoration: const BoxDecoration(
                  color: Color(0xFF151515),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, -5))],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
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
                                label: Text('Р${entry.key.row}-М${entry.key.seat} (${entry.value.short})'),
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
                  ),
                ),
              ),
            ),
        ],
      ),
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
