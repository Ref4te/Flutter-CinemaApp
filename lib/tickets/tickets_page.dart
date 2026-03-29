import 'package:flutter/material.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  static const List<_TicketItem> _mockTickets = [
    _TicketItem(
      movieTitle: 'Интерстеллар',
      hall: 'Зал 3',
      date: '5 апреля, 19:40',
      seat: 'Ряд 5, место 8',
    ),
    _TicketItem(
      movieTitle: 'Бегущий по лезвию 2049',
      hall: 'Зал 1',
      date: '9 апреля, 21:10',
      seat: 'Ряд 2, место 4',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Билеты')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _TicketInfoBanner(
            text:
                'Билеты пока отображаются из локальных заглушек. После интеграции БД/API здесь будут реальные бронирования.',
          ),
          const SizedBox(height: 14),
          ..._mockTickets.map((ticket) => _TicketCard(ticket: ticket)),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final _TicketItem ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1D1D1D),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number_rounded,
                  color: Color(0xFFE53935),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ticket.movieTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22, color: Color(0xFF333333)),
            Text('Дата: ${ticket.date}'),
            const SizedBox(height: 6),
            Text('Кинотеатр: ${ticket.hall}'),
            const SizedBox(height: 6),
            Text('Место: ${ticket.seat}'),
          ],
        ),
      ),
    );
  }
}

class _TicketInfoBanner extends StatelessWidget {
  const _TicketInfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketItem {
  const _TicketItem({
    required this.movieTitle,
    required this.hall,
    required this.date,
    required this.seat,
  });

  final String movieTitle;
  final String hall;
  final String date;
  final String seat;
}
