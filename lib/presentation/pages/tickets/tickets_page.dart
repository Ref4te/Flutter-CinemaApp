import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/booking_repository.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingRepository = BookingRepository();

    return Scaffold(
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

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF313131)),
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
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFF353535)),
                    _TicketInfoRow(label: 'Кинотеатр', value: ticket['cinemaName'] ?? '—'),
                    _TicketInfoRow(label: 'Адрес', value: ticket['cinemaAddress'] ?? '—'),
                    _TicketInfoRow(label: 'Зал', value: 'Зал ${ticket['hallId']}'),
                    _TicketInfoRow(label: 'Сеанс', value: '$dateStr в $timeStr'),
                    const SizedBox(height: 8),
                    const Text(
                      'Места:',
                      style: TextStyle(color: Color(0xFF9A9A9A), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...bookedSeats
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Ряд ${s['row']} • Место ${s['column']} (${s['type']})'),
                                Text('${s['price']} ₸', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    const Divider(height: 20, color: Color(0xFF353535)),
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
  const _TicketInfoRow({required this.label, required this.value});

  final String label;
  final String value;

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
              style: const TextStyle(color: Color(0xFF9A9A9A)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
