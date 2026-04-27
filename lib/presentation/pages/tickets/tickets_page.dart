import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../data/repositories/booking_repository.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingRepository = BookingRepository();

    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.language,
      builder: (context, language, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final cardColor = isDark ? const Color(0xFF1D1D1D) : Colors.white;
        final borderColor =
            isDark ? const Color(0xFF313131) : const Color(0xFFE1E4EA);
        final dividerColor =
            isDark ? const Color(0xFF353535) : const Color(0xFFE3E5EA);
        final secondaryTextColor =
            isDark ? const Color(0xFF9A9A9A) : const Color(0xFF6B7280);
        final emptyIconColor =
            isDark ? const Color(0xFF9A9A9A) : const Color(0xFF9CA3AF);

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.t('tickets')),
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: bookingRepository.getUserTickets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('${_errorLabel(language)}: ${snapshot.error}'),
                );
              }

              final tickets = snapshot.data ?? [];

              if (tickets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 64,
                        color: emptyIconColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _emptyLabel(language),
                        style: TextStyle(color: secondaryTextColor),
                      ),
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
                  final dateStr =
                      '${startTime.day}.${startTime.month}.${startTime.year}';
                  final timeStr =
                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

                  final List<dynamic> bookedSeats = ticket['seats'] ?? [];

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
                                ticket['movieTitle'] ?? _ticketLabel(language),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
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
                          value: ticket['cinemaName'] ?? '—',
                          labelColor: secondaryTextColor,
                          valueColor: theme.colorScheme.onSurface,
                        ),
                        _TicketInfoRow(
                          label: _hallLabel(language),
                          value: '${_hallLabel(language)} ${ticket['hallId'] ?? '—'}',
                          labelColor: secondaryTextColor,
                          valueColor: theme.colorScheme.onSurface,
                        ),
                        _TicketInfoRow(
                          label: AppStrings.t('session'),
                          value: '$dateStr ${_atLabel(language)} $timeStr',
                          labelColor: secondaryTextColor,
                          valueColor: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_seatsLabel(language)}:',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...bookedSeats
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_rowLabel(language)} ${s['row']} • ${AppStrings.t('seat')} ${s['column']} (${s['type']})',
                                    ),
                                    Text(
                                      '${s['price']} ₸',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        Divider(height: 20, color: dividerColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_totalLabel(language)}:',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
      },
    );
  }

  String _errorLabel(String language) {
    switch (language) {
      case 'English':
        return 'Error';
      case 'Қазақша':
        return 'Қате';
      default:
        return 'Ошибка';
    }
  }

  String _emptyLabel(String language) {
    switch (language) {
      case 'English':
        return 'You do not have purchased tickets yet';
      case 'Қазақша':
        return 'Сізде әзірге сатып алынған билеттер жоқ';
      default:
        return 'У вас пока нет купленных билетов';
    }
  }

  String _ticketLabel(String language) {
    switch (language) {
      case 'English':
        return 'Ticket';
      case 'Қазақша':
        return 'Билет';
      default:
        return 'Билет';
    }
  }

  String _hallLabel(String language) {
    switch (language) {
      case 'English':
        return 'Hall';
      case 'Қазақша':
        return 'Зал';
      default:
        return 'Зал';
    }
  }

  String _atLabel(String language) {
    switch (language) {
      case 'English':
        return 'at';
      case 'Қазақша':
        return 'сағ';
      default:
        return 'в';
    }
  }

  String _seatsLabel(String language) {
    switch (language) {
      case 'English':
        return 'Seats';
      case 'Қазақша':
        return 'Орындар';
      default:
        return 'Места';
    }
  }

  String _rowLabel(String language) {
    switch (language) {
      case 'English':
        return 'Row';
      case 'Қазақша':
        return 'Қатар';
      default:
        return 'Ряд';
    }
  }

  String _totalLabel(String language) {
    switch (language) {
      case 'English':
        return 'Total';
      case 'Қазақша':
        return 'Барлығы';
      default:
        return 'Итого';
    }
  }
}

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? labelColor;
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
              style: TextStyle(color: labelColor ?? const Color(0xFF9A9A9A)),
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
