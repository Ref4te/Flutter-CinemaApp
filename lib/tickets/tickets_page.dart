import 'package:flutter/material.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const tickets = [
      {
        'movie': 'Interstellar',
        'cinema': 'Cinema City #1',
        'datetime': '28.03.2026 19:30',
        'seat': 'Ряд 5, Место 8',
      },
      {
        'movie': 'Dune: Part Three',
        'cinema': 'Cinema City #2',
        'datetime': '30.03.2026 21:00',
        'seat': 'Ряд 3, Место 4',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Мои билеты')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'История и QR-коды билетов пока хранятся в заглушках. '
                'После интеграции БД/API здесь будут реальные данные.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...tickets.map(
            (ticket) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket['movie']!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text('Кинотеатр: ${ticket['cinema']}'),
                    Text('Время: ${ticket['datetime']}'),
                    Text('Место: ${ticket['seat']}'),
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
