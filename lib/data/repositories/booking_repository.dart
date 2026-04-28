import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/local_notification_service.dart';
import '../../domain/entities/session.dart';
import 'tmdb_repository.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TmdbRepository _tmdbRepository = TmdbRepository();

  Future<void> generateScheduleForAdmin() async {
    final user = _auth.currentUser;
    if (user == null || user.email != 'manat11@mail.ru') {
      print('Access denied: User is not admin');
      return;
    }

    final homeData = await _tmdbRepository.loadHomeData();
    var movies = homeData.movies.toList();
    movies.shuffle();
    final selectedMovies = movies.take(25).toList();

    if (selectedMovies.isEmpty) return;

    final cinemas = [
      {'name': 'Kinopark 8 Saryarka', 'address': 'пр. Туран, 24'},
      {'name': 'Chaplin Khan Shatyr', 'address': 'пр. Туран, 37'},
      {'name': 'Keruen Cinema', 'address': 'ул. Достык, 9'},
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final batch = _firestore.batch();
    final random = Random();

    for (var cinema in cinemas) {
      for (int hallId = 1; hallId <= 4; hallId++) {
        DateTime currentTime = today.add(const Duration(hours: 10)); 
        final endTimeLimit = today.add(const Duration(hours: 24)); 

        int lastMovieId = -1;

        while (currentTime.add(const Duration(minutes: 60)).isBefore(endTimeLimit)) {
          var availableMovies = selectedMovies.where((m) => m.id != lastMovieId).toList();
          if (availableMovies.isEmpty) availableMovies = selectedMovies;
          final movie = availableMovies[random.nextInt(availableMovies.length)];
          lastMovieId = movie.id;

          int duration = _parseDuration(movie.duration);
          final sessionEndTime = currentTime.add(Duration(minutes: duration));
          if (sessionEndTime.isAfter(endTimeLimit)) break;

          final capacity = [60, 70, 80][random.nextInt(3)];
          final seats = _generateSeats(capacity);

          final sessionRef = _firestore.collection('sessions').doc();
          batch.set(sessionRef, {
            'movieId': movie.id,
            'movieTitle': movie.title,
            'startTime': Timestamp.fromDate(currentTime),
            'endTime': Timestamp.fromDate(sessionEndTime),
            'cinemaName': cinema['name'],
            'cinemaAddress': cinema['address'],
            'hallId': hallId,
            'seats': seats.map((s) => s.toMap()).toList(),
          });

          DateTime nextTime = sessionEndTime.add(const Duration(minutes: 20));
          int minute = nextTime.minute;
          if (minute % 10 != 0) {
            nextTime = nextTime.add(Duration(minutes: 10 - (minute % 10)));
          }
          currentTime = DateTime(nextTime.year, nextTime.month, nextTime.day, nextTime.hour, nextTime.minute);
        }
      }
    }

    await batch.commit();
  }

  Future<void> clearAllData() async {
    final user = _auth.currentUser;
    if (user == null || user.email != 'manat11@mail.ru') {
      print('Access denied: User is not admin');
      return;
    }

    // Удаление всех сессий
    final sessions = await _firestore.collection('sessions').get();
    final sessionBatch = _firestore.batch();
    for (var doc in sessions.docs) {
      sessionBatch.delete(doc.reference);
    }
    await sessionBatch.commit();

    // Удаление всех билетов
    final tickets = await _firestore.collection('tickets').get();
    final ticketBatch = _firestore.batch();
    for (var doc in tickets.docs) {
      ticketBatch.delete(doc.reference);
    }
    await ticketBatch.commit();
  }

  int _parseDuration(String durationStr) {
    try {
      final hoursMatch = RegExp(r'(\d+)ч').firstMatch(durationStr);
      final minsMatch = RegExp(r'(\d+)м').firstMatch(durationStr);
      int total = 0;
      if (hoursMatch != null) total += int.parse(hoursMatch.group(1)!) * 60;
      if (minsMatch != null) total += int.parse(minsMatch.group(1)!);
      return total > 0 ? total : 120;
    } catch (_) {
      return 120;
    }
  }

  List<Seat> _generateSeats(int capacity) {
    final cols = 10;
    final rows = (capacity / cols).ceil();
    List<Seat> seats = [];
    final startVipRow = (rows / 2).floor();
    final endVipRow = startVipRow + 2;

    for (int r = 1; r <= rows; r++) {
      for (int c = 1; c <= cols; c++) {
        if (seats.length >= capacity) break;
        bool isVip = (r >= startVipRow && r <= endVipRow) && (c >= 4 && c <= 7);
        seats.add(Seat(
          id: 'r${r}c$c',
          row: r,
          column: c,
          isAvailable: true,
          isVip: isVip,
        ));
      }
    }
    return seats;
  }

  Stream<List<MovieSession>> getSessions(int movieId) {
    return _firestore
        .collection('sessions')
        .where('movieId', isEqualTo: movieId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MovieSession.fromFirestore(doc))
            .toList());
  }

  Stream<MovieSession> getSessionStream(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => MovieSession.fromFirestore(doc));
  }

  Future<bool> bookSeats(String sessionId, Map<String, String> selectedSeatsWithTariff) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final sessionRef = _firestore.collection('sessions').doc(sessionId);
    DateTime? startTime;
    String movieTitle = '';
    String cinemaAddress = '';

    final success = await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>;
      final seatsList = List<Map<String, dynamic>>.from(data['seats']);
      final prices = Map<String, dynamic>.from(data['prices'] as Map<String, dynamic>? ?? const {});
      
      List<Map<String, dynamic>> bookedSeatsData = [];
      int totalBookingPrice = 0;

      for (var entry in selectedSeatsWithTariff.entries) {
        final seatId = entry.key;
        final tariff = entry.value;

        final seatIndex = seatsList.indexWhere((s) => s['id'] == seatId);
        if (seatIndex == -1 || seatsList[seatIndex]['isAvailable'] == false) {
          return false;
        }

        final bool isVip = seatsList[seatIndex]['isVip'] ?? false;
        int price = isVip ? _vipPrice(prices) : _getPriceByTariff(tariff, prices);

        seatsList[seatIndex]['isAvailable'] = false;
        
        bookedSeatsData.add({
          'seat_id': seatId,
          'row': seatsList[seatIndex]['row'],
          'column': seatsList[seatIndex]['column'],
          'type': tariff,
          'price': price,
        });
        totalBookingPrice += price;
      }

      transaction.update(sessionRef, {'seats': seatsList});

      final ticketRef = _firestore.collection('tickets').doc();
      transaction.set(ticketRef, {
        'userId': user.uid,
        'sessionId': sessionId,
        'movieId': data['movieId'],
        'movieTitle': data['movieTitle'],
        'cinemaName': data['cinemaName'],
        'cinemaAddress': data['cinemaAddress'] ?? '',
        'hallId': data['hallId'],
        'startTime': data['startTime'],
        'seats': bookedSeatsData,
        'totalPrice': totalBookingPrice,
        'created_at': FieldValue.serverTimestamp(),
      });

      startTime = (data['startTime'] as Timestamp).toDate();
      movieTitle = data['movieTitle']?.toString() ?? '';
      cinemaAddress = data['cinemaAddress']?.toString() ?? data['cinemaName']?.toString() ?? '';

      return true;
    });

    if (success && startTime != null) {
      await LocalNotificationService.instance.scheduleTicketReminder(
        ticketId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        movieTitle: movieTitle,
        sessionStart: startTime!,
        cinemaAddress: cinemaAddress,
      );
    }

    return success;
  }

  int _getPriceByTariff(String tariff, Map<String, dynamic> prices) {
    switch (tariff.toLowerCase()) {
      case 'детский': return _readPrice(prices['child'], 1200);
      case 'студенческий': return _readPrice(prices['student'], 1800);
      case 'взрослый': return _readPrice(prices['adult'], 2500);
      default: return _readPrice(prices['adult'], 2500);
    }
  }

  int _vipPrice(Map<String, dynamic> prices) => _readPrice(prices['vip'], 5000);

  int _readPrice(dynamic value, int fallback) {
    if (value is int && value >= 0) return value;
    if (value is num && value >= 0) return value.toInt();
    return fallback;
  }

  Stream<List<Map<String, dynamic>>> getUserTickets() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('tickets')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).toList();
          final now = DateTime.now();
          docs.sort((a, b) {
            final aStart = (a['startTime'] as Timestamp?)?.toDate();
            final bStart = (b['startTime'] as Timestamp?)?.toDate();

            if (aStart == null && bStart == null) return 0;
            if (aStart == null) return 1;
            if (bStart == null) return -1;

            final aPast = aStart.isBefore(now);
            final bPast = bStart.isBefore(now);

            if (aPast != bPast) {
              return aPast ? 1 : -1;
            }

            if (!aPast) {
              return aStart.compareTo(bStart);
            }

            return bStart.compareTo(aStart);
          });
          return docs;
        });
  }
}
