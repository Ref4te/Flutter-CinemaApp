import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/booking_repository.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingRepository = BookingRepository();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF303030) : const Color(0xFFE6E6E6);
    final dividerColor = isDark ? const Color(0xFF353535) : const Color(0xFFE8E8E8);
    final seatCellColor = isDark ? const Color(0xFF242424) : const Color(0xFFF7F7F7);
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryText = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF7A7A7A);

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(title: const Text('Мои Билеты')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: bookingRepository.getUserTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('У вас пока нет купленных билетов', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final startTime = (ticket['startTime'] as Timestamp).toDate();
              final dateStr = '${startTime.day}.${startTime.month}.${startTime.year}';
              final timeStr =
                  '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

              final List<dynamic> bookedSeats = ticket['seats'] ?? [];
              final isPast = startTime.isBefore(DateTime.now());

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? const Color(0x22000000) : const Color(0x11000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number, color: Color(0xFFE53935)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ticket['movieTitle'] ?? 'Билет',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isPast ? Colors.redAccent : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: dividerColor),
                    _TicketInfoRow(label: 'Кинотеатр', value: ticket['cinemaName'] ?? '—'),
                    _TicketInfoRow(label: 'Адрес', value: ticket['cinemaAddress'] ?? '—'),
                    _TicketInfoRow(label: 'Зал', value: 'Зал ${ticket['hallId']}'),
                    _TicketInfoRow(
                      label: 'Сеанс',
                      value: '$dateStr в $timeStr',
                      valueColor: isPast ? Colors.redAccent : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Места:',
                      style: TextStyle(color: secondaryText, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...bookedSeats
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: seatCellColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ряд ${s['row']} • Место ${s['column']} (${s['type']})',
                                    style: TextStyle(color: primaryText),
                                  ),
                                  Text(
                                    '${s['price']} ₸',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    Divider(height: 20, color: dividerColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Итого:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${ticket['totalPrice']} ₸',
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF7A7A7A)),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }
}
