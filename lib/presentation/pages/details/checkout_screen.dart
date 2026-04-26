import 'package:flutter/material.dart';

import '../../../data/services/firestore_booking_service.dart';
import '../navigation/main_navigation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.sessionId,
    required this.movieTitle,
    required this.hallName,
    required this.sessionTime,
    required this.seats,
    required this.totalPrice,
  });

  final String sessionId;
  final String movieTitle;
  final String hallName;
  final String sessionTime;
  final List<CheckoutSeatLine> seats;
  final int totalPrice;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirestoreBookingService _bookingService = FirestoreBookingService();
  bool _isPaying = false;

  Future<void> _pay(BuildContext context) async {
    if (_isPaying) {
      return;
    }

    setState(() => _isPaying = true);
    try {
      await _bookingService.bookSeatsTransaction(
        sessionId: widget.sessionId,
        movieTitle: widget.movieTitle,
        seats: widget.seats
            .map(
              (seat) => FirestoreBookingSeat(
                seatNumber: seat.seatNumber,
                tariff: seat.tariff,
                price: seat.price,
              ),
            )
            .toList(growable: false),
        totalPrice: widget.totalPrice,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Успешно забронировано')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } on SeatAlreadyBookedException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Места уже заняты: ${e.seats.join(', ')}')),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка оплаты: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1D1D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF303030)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Итоговый чек',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _CheckoutRow(label: 'Фильм', value: widget.movieTitle),
                  _CheckoutRow(label: 'Зал', value: widget.hallName),
                  _CheckoutRow(label: 'Время', value: widget.sessionTime),
                  const SizedBox(height: 8),
                  const Text('Места', style: TextStyle(color: Color(0xFFAFAFAF), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...widget.seats.map(
                    (seat) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${seat.seatNumber} • ${seat.tariff} • ${seat.price} ₸',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const Divider(height: 22, color: Color(0xFF3A3A3A)),
                  Text(
                    'Итого: ${widget.totalPrice} ₸',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaying ? null : () => _pay(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
                child: Text(_isPaying ? 'Оплата...' : 'Оплатить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutRow extends StatelessWidget {
  const _CheckoutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(label, style: const TextStyle(color: Color(0xFFAFAFAF))),
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

class CheckoutSeatLine {
  const CheckoutSeatLine({
    required this.row,
    required this.seat,
    required this.seatNumber,
    required this.tariff,
    required this.price,
  });

  final int row;
  final int seat;
  final String seatNumber;
  final String tariff;
  final int price;
}
