import 'package:flutter/material.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  static const List<_TicketItem> _tickets = [
    _TicketItem(movie: 'Интерстеллар', session: 'Сегодня, 20:30', hall: 'Зал 3'),
    _TicketItem(movie: 'Джокер', session: '31 марта, 18:10', hall: 'Зал 1'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои билеты')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1D1D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2F2F2F)),
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
                const SizedBox(height: 10),
                Text('Сеанс: ${ticket.session}'),
                Text('Локация: ${ticket.hall}'),
                const SizedBox(height: 10),
                const Text(
                  'QR и места сейчас отображаются как заглушка до подключения БД/API.',
                  style: TextStyle(color: Color(0xFF9A9A9A)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TicketItem {
  const _TicketItem({
    required this.movie,
    required this.session,
    required this.hall,
  });

  final String movie;
  final String session;
  final String hall;
}
