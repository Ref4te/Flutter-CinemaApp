import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeatAlreadyBookedException implements Exception {
  SeatAlreadyBookedException(this.seats);

  final List<String> seats;

  @override
  String toString() => 'Seats already booked: ${seats.join(', ')}';
}

class FirestoreBookingSeat {
  const FirestoreBookingSeat({
    required this.seatNumber,
    required this.tariff,
    required this.price,
  });

  final String seatNumber;
  final String tariff;
  final int price;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'seat_number': seatNumber,
      'type': tariff,
      'price': price,
    };
  }
}

class FirestoreBookingService {
  FirestoreBookingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> bookSeatsTransaction({
    required String sessionId,
    required String movieTitle,
    required List<FirestoreBookingSeat> seats,
    required int totalPrice,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('Пользователь не авторизован');
    }
    if (seats.isEmpty) {
      throw StateError('Не выбраны места для бронирования');
    }

    final sessionRef = _firestore.collection('sessions').doc(sessionId);
    final bookingRef = _firestore.collection('bookings').doc();

    await _firestore.runTransaction((transaction) async {
      final sessionSnapshot = await transaction.get(sessionRef);
      if (!sessionSnapshot.exists) {
        throw StateError('Сеанс не найден');
      }

      final sessionData = sessionSnapshot.data()!;
      final List<dynamic> bookedDynamic =
          (sessionData['booked_seats'] as List<dynamic>? ?? <dynamic>[]);
      final Set<String> alreadyBooked =
          bookedDynamic.map((item) => item.toString()).toSet();

      final List<String> requestedSeats =
          seats.map((seat) => seat.seatNumber).toList(growable: false);

      final List<String> conflicts = requestedSeats
          .where(alreadyBooked.contains)
          .toList(growable: false);

      if (conflicts.isNotEmpty) {
        throw SeatAlreadyBookedException(conflicts);
      }

      final Set<String> updatedBooked = <String>{...alreadyBooked, ...requestedSeats};

      transaction.update(sessionRef, <String, dynamic>{
        'booked_seats': updatedBooked.toList(growable: false),
        'updated_at': FieldValue.serverTimestamp(),
      });

      transaction.set(bookingRef, <String, dynamic>{
        'user_id': userId,
        'session_id': sessionId,
        'movie_title': movieTitle,
        'selected_seats': seats.map((seat) => seat.toMap()).toList(growable: false),
        'total_price': totalPrice,
        'status': 'оплачено',
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
