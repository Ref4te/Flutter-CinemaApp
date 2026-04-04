import 'package:flutter/material.dart';

class SeatSelectionScreen extends StatelessWidget {
  const SeatSelectionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор мест')),
      body: Center(
        child: Text(
          'SeatSelectionScreen(sessionId: $sessionId)',
          style: const TextStyle(fontSize: 18, color: Color(0xFFD0D0D0)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
