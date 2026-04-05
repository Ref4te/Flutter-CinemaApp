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

  final Set<TicketSeat> _selectedSeats = <TicketSeat>{};
  late final Set<TicketSeat> _occupiedSeats;
  TicketSeat? _focusedSeat;

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

  int _seatPrice(TicketSeat seat) => _isVip(seat) ? _vipPrice : _standardPrice;

  int get _totalPrice => _selectedSeats.fold<int>(0, (sum, seat) => sum + _seatPrice(seat));

  void _onSeatTap(TicketSeat seat) {
    if (_occupiedSeats.contains(seat)) {
      return;
    }
    setState(() {
      _focusedSeat = seat;
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
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

    final sortedSeats = _selectedSeats.toList()
      ..sort((a, b) => a.row != b.row ? a.row.compareTo(b.row) : a.seat.compareTo(b.seat));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          movieTitle: widget.movieTitle,
          hallName: widget.hallName,
          sessionTime: widget.sessionTime,
          seats: sortedSeats,
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор мест'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _ScreenArc(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 12, 8, _selectedSeats.isEmpty ? 12 : 138 + bottomInset),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 3.2,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: Center(
                      child: SizedBox(
                        width: 380,
                        child: Column(
                          children: List.generate(_rows, (rowIndex) {
                            final row = rowIndex + 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_seatsPerRow, (seatIndex) {
                                  final seatNumber = seatIndex + 1;
                                  final seat = TicketSeat(row: row, seat: seatNumber);
                                  final isOccupied = _occupiedSeats.contains(seat);
                                  final isSelected = _selectedSeats.contains(seat);
                                  final isVip = _isVip(seat);

                                  return _SeatWidget(
                                    seat: seat,
                                    isOccupied: isOccupied,
                                    isSelected: isSelected,
                                    isVip: isVip,
                                    onTap: () => _onSeatTap(seat),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_focusedSeat != null)
            DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.14,
              maxChildSize: 0.32,
              builder: (context, controller) {
                final focused = _focusedSeat!;
                final isSelected = _selectedSeats.contains(focused);
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D1D1D),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      _selectedSeats.isEmpty ? 16 : 86 + bottomInset,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 56,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF444444),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ряд ${focused.row}, Место ${focused.seat}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Цена: ${_seatPrice(focused)} ₸',
                        style: const TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _onSeatTap(focused),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? const Color(0xFF3B3B3B) : const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(isSelected ? 'Убрать' : 'Добавить'),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedSeats.length} билет(ов) • $_totalPrice ₸',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _selectedSeats.map((seat) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Chip(
                                backgroundColor: const Color(0xFF252525),
                                label: Text('Р${seat.row}-М${seat.seat}'),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => _removeSeat(seat),
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
      borderColor = const Color(0xFF9D9D9D);
      fillColor = const Color(0xFF9D9D9D);
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
            color: isSelected || isOccupied ? Colors.black : const Color(0xFFCFCFCF),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ScreenArc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFF8EC5FF)],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.elliptical(180, 58),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x668EC5FF),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        alignment: const Alignment(0, -0.3),
        child: const Text(
          'Экран',
          style: TextStyle(
            color: Color(0xFF0E2340),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
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
