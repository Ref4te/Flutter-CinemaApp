import 'package:cloud_firestore/cloud_firestore.dart';

class Seat {
  final String id;
  final int row;
  final int column;
  final bool isAvailable;
  final bool isVip;

  Seat({
    required this.id,
    required this.row,
    required this.column,
    required this.isAvailable,
    required this.isVip,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'row': row,
      'column': column,
      'isAvailable': isAvailable,
      'isVip': isVip,
    };
  }

  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      id: map['id'] ?? '',
      row: map['row'] ?? 0,
      column: map['column'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      isVip: map['isVip'] ?? false,
    );
  }
}

class MovieSession {
  final String id;
  final int movieId;
  final String movieTitle;
  final DateTime startTime;
  final DateTime endTime;
  final String cinemaName;
  final int hallId;
  final List<Seat> seats;

  MovieSession({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.startTime,
    required this.endTime,
    required this.cinemaName,
    required this.hallId,
    required this.seats,
  });

  Map<String, dynamic> toMap() {
    return {
      'movieId': movieId,
      'movieTitle': movieTitle,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'cinemaName': cinemaName,
      'hallId': hallId,
      'seats': seats.map((s) => s.toMap()).toList(),
    };
  }

  factory MovieSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MovieSession(
      id: doc.id,
      movieId: data['movieId'] ?? 0,
      movieTitle: data['movieTitle'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      cinemaName: data['cinemaName'] ?? '',
      hallId: data['hallId'] ?? 0,
      seats: (data['seats'] as List? ?? [])
          .map((s) => Seat.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
