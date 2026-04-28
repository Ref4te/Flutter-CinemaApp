import 'package:flutter/material.dart';
import '../../../domain/entities/session.dart';
import '../../../data/repositories/booking_repository.dart';

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
  final BookingRepository _bookingRepository = BookingRepository();
  
  // key: seatId, value: tariff
  final Map<String, String> _selectedSeats = {};
  String? _focusedSeatId;
  String _activeTariff = 'Взрослый';
  _BottomPanelMode _bottomPanelMode = _BottomPanelMode.hidden;

  void _focusSeat(Seat seat, Map<String, int> prices) {
    if (!seat.isAvailable) return;
    final availableTariffs = <String>[
      if ((prices['child'] ?? 0) > 0) 'Детский',
      if ((prices['student'] ?? 0) > 0) 'Студенческий',
      if ((prices['adult'] ?? 0) > 0) 'Взрослый',
    ];
    
    setState(() {
      _focusedSeatId = seat.id;
      _activeTariff = _selectedSeats[seat.id] ?? (availableTariffs.isNotEmpty ? availableTariffs.last : 'Взрослый');
      _bottomPanelMode = _BottomPanelMode.seatInfo;
    });
  }

  void _addFocusedSeat(Seat seat) {
    setState(() {
      _selectedSeats[seat.id] = _activeTariff;
      _bottomPanelMode = _BottomPanelMode.cart;
    });
  }

  void _removeSeat(String seatId) {
    setState(() {
      _selectedSeats.remove(seatId);
      if (_selectedSeats.isEmpty) {
        _bottomPanelMode = _focusedSeatId == null ? _BottomPanelMode.hidden : _BottomPanelMode.seatInfo;
      }
    });
  }

  int _calculatePrice(Seat seat, String tariff, Map<String, int> prices) {
    if (seat.isVip) return prices['vip'] ?? 5000;
    switch (tariff) {
      case 'Детский': return prices['child'] ?? 1200;
      case 'Студенческий': return prices['student'] ?? 1800;
      case 'Взрослый': return prices['adult'] ?? 2500;
      default: return prices['adult'] ?? 2500;
    }
  }

  int _getTotalPrice(List<Seat> allSeats, Map<String, int> prices) {
    int total = 0;
    _selectedSeats.forEach((seatId, tariff) {
      final seat = allSeats.firstWhere((s) => s.id == seatId);
      total += _calculatePrice(seat, tariff, prices);
    });
    return total;
  }

  Future<void> _handleBooking() async {
    if (_selectedSeats.isEmpty) return;

    setState(() => _bottomPanelMode = _BottomPanelMode.hidden);
    
    final success = await _bookingRepository.bookSeats(
      widget.sessionId,
      _selectedSeats,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Бронирование успешно завершено!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка бронирования. Возможно, места уже заняты.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final hasBottomPanel = _bottomPanelMode != _BottomPanelMode.hidden;
    final bottomOffset = hasBottomPanel ? 210 + bottomInset : 0.0;

    return StreamBuilder<MovieSession>(
      stream: _bookingRepository.getSessionStream(widget.sessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Сеанс не найден')));
        }

        final session = snapshot.data!;
        final focusedSeat = _focusedSeatId != null 
            ? session.seats.firstWhere((s) => s.id == _focusedSeatId, orElse: () => session.seats.first) 
            : null;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          appBar: AppBar(
            title: const Text('Выбор мест'),
            centerTitle: true,
            backgroundColor: const Color(0xFF151515),
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, 12, 8, bottomOffset),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 2.0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ScreenArc(),
                        const SizedBox(height: 28),
                        _buildSeatGrid(session.seats, session.prices),
                      ],
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
                      boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, -5))],
                    ),
                    child: SafeArea(
                      top: false,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _bottomPanelMode == _BottomPanelMode.seatInfo && focusedSeat != null
                            ? _buildSeatInfoPanel(focusedSeat, session.prices)
                            : _buildCartPanel(session),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeatGrid(List<Seat> seats, Map<String, int> prices) {
    final maxRow = seats.map((s) => s.row).fold(0, (prev, curr) => curr > prev ? curr : prev);
    
    return Column(
      children: List.generate(maxRow, (rIndex) {
        final row = rIndex + 1;
        final rowSeats = seats.where((s) => s.row == row).toList()..sort((a, b) => a.column.compareTo(b.column));
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: rowSeats.map((seat) {
              return _SeatWidget(
                seat: seat,
                isSelected: _selectedSeats.containsKey(seat.id),
                onTap: () => _focusSeat(seat, prices),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildSeatInfoPanel(Seat seat, Map<String, int> prices) {
    final tariffs = <String>[
      if ((prices['child'] ?? 0) > 0) 'Детский',
      if ((prices['student'] ?? 0) > 0) 'Студенческий',
      if ((prices['adult'] ?? 0) > 0) 'Взрослый',
    ];
    final canBookVip = (prices['vip'] ?? 0) > 0;
    return Column(
      key: const ValueKey('seat-info-panel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ряд ${seat.row}, Место ${seat.column} ${seat.isVip ? "(VIP)" : ""}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (!seat.isVip) ...[
          const Text('Тариф', style: TextStyle(color: Color(0xFFB7B7B7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tariffs.map((t) {
              return ChoiceChip(
                selected: _activeTariff == t,
                label: Text('$t • ${_calculatePrice(seat, t, prices)} ₸'),
                onSelected: (_) => setState(() => _activeTariff = t),
              );
            }).toList(),
          ),
        ] else
          Text('VIP • ${prices['vip'] ?? 5000} ₸', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: seat.isVip ? (canBookVip ? () => _addFocusedSeat(seat) : null) : (tariffs.isEmpty ? null : () => _addFocusedSeat(seat)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_selectedSeats.containsKey(seat.id) ? 'Обновить' : 'Добавить'),
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

  Widget _buildCartPanel(MovieSession session) {
    return Column(
      key: const ValueKey('cart-panel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedSeats.length} билет(ов) • ${_getTotalPrice(session.seats, session.prices)} ₸',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _selectedSeats.entries.map((entry) {
              final seatId = entry.key;
              final seat = session.seats.firstWhere((s) => s.id == seatId);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Chip(
                  backgroundColor: const Color(0xFF262626),
                  label: Text('Р${seat.row}-М${seat.column}'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeSeat(seatId),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Забронировать'),
          ),
        ),
      ],
    );
  }
}

class _SeatWidget extends StatelessWidget {
  const _SeatWidget({
    required this.seat,
    required this.isSelected,
    required this.onTap,
  });

  final Seat seat;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFF5A5A5A);
    Color fillColor = Colors.transparent;

    if (seat.isVip) borderColor = const Color(0xFFFFC85A);
    if (!seat.isAvailable) {
      borderColor = const Color(0xFFA4A4A4);
      fillColor = const Color(0xFFA4A4A4);
    }
    if (isSelected) {
      borderColor = const Color(0xFFE53935);
      fillColor = const Color(0xFFE53935);
    }

    return GestureDetector(
      onTap: seat.isAvailable ? onTap : null,
      child: Container(
        width: 26,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '${seat.column}',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isSelected || !seat.isAvailable ? Colors.black : const Color(0xFFCFCFCF),
          ),
        ),
      ),
    );
  }
}

class _ScreenArc extends StatelessWidget {
  const _ScreenArc();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 40,
      child: CustomPaint(
        painter: _ScreenPainter(),
        child: const Center(
          child: Text(
            'ЭКРАН',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
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
    final paint = Paint()
      ..color = const Color(0xFFE53935).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width / 2, 0, size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

enum _BottomPanelMode { hidden, seatInfo, cart }
