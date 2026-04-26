import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/settings/app_settings.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1D1D1D) : Colors.white;
    final borderColor =
    isDark ? const Color(0xFF313131) : const Color(0xFFE1E4EA);
    final dividerColor =
    isDark ? const Color(0xFF353535) : const Color(0xFFE3E5EA);
    final secondaryTextColor =
    isDark ? const Color(0xFF9A9A9A) : const Color(0xFF6B7280);
    final primaryTextColor =
    isDark ? Colors.white : const Color(0xFF1F2937);

    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.language,
      builder: (context, language, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.t('tickets')),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tickets.length,
            itemBuilder: (context, index) {
              final ticket = _tickets[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: isDark
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          color: Color(0xFFE53935),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ticket.movie,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: dividerColor),
                    _TicketInfoRow(
                      label: AppStrings.t('cinema'),
                      value: ticket.cinema,
                      labelColor: secondaryTextColor,
                      valueColor: primaryTextColor,
                    ),
                    _TicketInfoRow(
                      label: AppStrings.t('session'),
                      value: ticket.dateTime,
                      labelColor: secondaryTextColor,
                      valueColor: primaryTextColor,
                    ),
                    _TicketInfoRow(
                      label: AppStrings.t('seat'),
                      value: ticket.seat,
                      labelColor: secondaryTextColor,
                      valueColor: primaryTextColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.t('ticket_note'),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

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
              style: TextStyle(color: labelColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
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