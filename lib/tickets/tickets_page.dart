import 'package:flutter/material.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  static const List<_TicketStub> _tickets = [
    _TicketStub(
      movieTitle: 'Микки 17',
      cinema: 'Cinema City',
      dateTime: '01 апреля, 19:30',
      hall: 'Зал 3',
      seats: 'Ряд 5, места 7-8',
    ),
    _TicketStub(
      movieTitle: 'Фуриоса',
      cinema: 'Grand Hall',
      dateTime: '06 апреля, 21:10',
      hall: 'IMAX',
      seats: 'Ряд 2, место 5',
    ),
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
          return Card(
            color: const Color(0xFF1D1D1D),
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.movieTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _TicketLine(icon: Icons.location_on_outlined, text: ticket.cinema),
                  _TicketLine(icon: Icons.schedule, text: ticket.dateTime),
                  _TicketLine(icon: Icons.theaters_outlined, text: ticket.hall),
                  _TicketLine(icon: Icons.event_seat_outlined, text: ticket.seats),
                  const Divider(height: 22, color: Color(0xFF393939)),
                  const Text(
                    'QR и статус билета будут доступны после подключения БД/API.',
                    style: TextStyle(color: Color(0xFF9A9A9A)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TicketLine extends StatelessWidget {
  const _TicketLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _TicketStub {
  const _TicketStub({
    required this.movieTitle,
    required this.cinema,
    required this.dateTime,
    required this.hall,
    required this.seats,
  });

  final String movieTitle;
  final String cinema;
  final String dateTime;
  final String hall;
  final String seats;
}
