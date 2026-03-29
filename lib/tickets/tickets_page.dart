import 'package:flutter/material.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  static const List<_TicketItem> _tickets = [
    _TicketItem(
      movie: 'Дюна: Часть вторая',
      cinema: 'Кинотеатр IMAX City',
      dateTime: '15 апреля, 19:30',
      seat: 'Ряд 6 • Место 11',
    ),
    _TicketItem(
      movie: 'Интерстеллар',
      cinema: 'Cinema Hall Premium',
      dateTime: '21 апреля, 21:10',
      seat: 'Ряд 3 • Место 7',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Билеты')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
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
                        ticket.movie,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFF353535)),
                _TicketInfoRow(label: 'Кинотеатр', value: ticket.cinema),
                _TicketInfoRow(label: 'Сеанс', value: ticket.dateTime),
                _TicketInfoRow(label: 'Место', value: ticket.seat),
                const SizedBox(height: 8),
                const Text(
                  'Данные билета пока используются как заглушка без БД/API.',
                  style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
                ),
              ],
            ),
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

class _TicketItem {
  const _TicketItem({
    required this.movie,
    required this.cinema,
    required this.dateTime,
    required this.seat,
  });

  final String movie;
  final String cinema;
  final String dateTime;
  final String seat;
}
