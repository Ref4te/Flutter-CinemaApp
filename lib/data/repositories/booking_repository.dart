import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/session.dart';
import 'tmdb_repository.dart';

class BookingRepository {
  static const String _adminEmail = 'manat11@mail.ru';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TmdbRepository _tmdbRepository = TmdbRepository();

  bool get isAdmin => _auth.currentUser?.email == _adminEmail;

  Future<void> _ensureAdmin() async {
    if (!isAdmin) {
      throw StateError('Access denied: user is not admin');
    }
  }

  Future<void> generateScheduleForAdmin() async {
    await _ensureAdmin();

    final homeData = await _tmdbRepository.loadHomeData();
    var movies = homeData.movies.toList();
    movies.shuffle();
    final selectedMovies = movies.take(30).toList();

    if (selectedMovies.isEmpty) return;

    final cinemas = [
      {'name': 'Kinopark 8 Saryarka', 'address': 'пр. Туран, 24'},
      {'name': 'Chaplin Khan Shatyr', 'address': 'пр. Туран, 37'},
      {'name': 'Keruen Cinema', 'address': 'ул. Достык, 9'},
    ];

    final random = Random();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final operations = <({DocumentReference ref, Map<String, dynamic> data})>[];

    for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
      final baseDate = today.add(Duration(days: dayOffset));
      final dayStart = DateTime(baseDate.year, baseDate.month, baseDate.day, 10);
      final dayEnd = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
      ).add(const Duration(days: 1, hours: 1));

      for (var cinema in cinemas) {
        for (int hallId = 1; hallId <= 3; hallId++) {
          DateTime currentTime = dayStart;
          int lastMovieId = -1;

          while (currentTime.isBefore(dayEnd)) {
            var availableMovies = selectedMovies
                .where((m) => m.id != lastMovieId)
                .toList();
            if (availableMovies.isEmpty) availableMovies = selectedMovies;
            final movie =
                availableMovies[random.nextInt(availableMovies.length)];
            lastMovieId = movie.id;

            final duration = _parseDuration(movie.duration);
            final sessionEndTime = currentTime.add(Duration(minutes: duration));
            if (sessionEndTime.isAfter(dayEnd)) {
              break;
            }

            final capacity = [60, 70, 80][random.nextInt(3)];
            final seats = _generateSeats(capacity);

            operations.add((
              ref: _firestore.collection('sessions').doc(),
              data: {
                'movieId': movie.id,
                'movieTitle': movie.title,
                'startTime': Timestamp.fromDate(currentTime),
                'endTime': Timestamp.fromDate(sessionEndTime),
                'cinemaName': cinema['name'],
                'hallId': hallId,
                'seats': seats.map((s) => s.toMap()).toList(),
              },
            ));

            currentTime = sessionEndTime.add(const Duration(minutes: 20));
          }
        }
      }
    }

    await _commitSetOperations(operations);
  }

  Future<void> clearAllData() async {
    await deleteSessions();
    await _deleteTickets();
  }

  Future<void> deleteSessions({int? movieId}) async {
    await _ensureAdmin();

    Query<Map<String, dynamic>> query = _firestore.collection('sessions');
    if (movieId != null) {
      query = query.where('movieId', isEqualTo: movieId);
    }
    final sessions = await query.get();
    await _commitDeleteDocs(sessions.docs.map((doc) => doc.reference).toList());
    await _deleteTickets(movieId: movieId);
  }

  Future<void> clearBookedSeats({int? movieId}) async {
    await _ensureAdmin();

    Query<Map<String, dynamic>> query = _firestore.collection('sessions');
    if (movieId != null) {
      query = query.where('movieId', isEqualTo: movieId);
    }

    final sessions = await query.get();
    final operations = <({DocumentReference ref, Map<String, dynamic> data})>[];

    for (final doc in sessions.docs) {
      final data = doc.data();
      final rawSeats = List<Map<String, dynamic>>.from(data['seats'] ?? []);
      final resetSeats = rawSeats
          .map((seat) => {
                ...seat,
                'isAvailable': true,
              })
          .toList();

      operations.add((
        ref: doc.reference,
        data: {'seats': resetSeats},
      ));
    }

    await _commitUpdateOperations(operations);
    await _deleteTickets(movieId: movieId);
  }

  Future<void> _deleteTickets({int? movieId}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('tickets');
    if (movieId != null) {
      query = query.where('movieId', isEqualTo: movieId);
    }
    final tickets = await query.get();
    await _commitDeleteDocs(tickets.docs.map((doc) => doc.reference).toList());
  }

  Future<void> _commitDeleteDocs(List<DocumentReference> refs) async {
    for (var i = 0; i < refs.length; i += 450) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(i).take(450)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> _commitSetOperations(
    List<({DocumentReference ref, Map<String, dynamic> data})> operations,
  ) async {
    for (var i = 0; i < operations.length; i += 450) {
      final batch = _firestore.batch();
      for (final op in operations.skip(i).take(450)) {
        batch.set(op.ref, op.data);
      }
      await batch.commit();
    }
  }

  Future<void> _commitUpdateOperations(
    List<({DocumentReference ref, Map<String, dynamic> data})> operations,
  ) async {
    for (var i = 0; i < operations.length; i += 450) {
      final batch = _firestore.batch();
      for (final op in operations.skip(i).take(450)) {
        batch.update(op.ref, op.data);
      }
      await batch.commit();
    }
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

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>;
      final seatsList = List<Map<String, dynamic>>.from(data['seats']);
      
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
        int price = isVip ? 5000 : _getPriceByTariff(tariff);

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
        'hallId': data['hallId'],
        'startTime': data['startTime'],
        'seats': bookedSeatsData,
        'totalPrice': totalBookingPrice,
        'created_at': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  int _getPriceByTariff(String tariff) {
    switch (tariff.toLowerCase()) {
      case 'детский': return 1200;
      case 'студенческий': return 1800;
      case 'взрослый': return 2500;
      default: return 2500;
    }
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
          docs.sort((a, b) {
            final aTime = (a['created_at'] as Timestamp?) ?? Timestamp.now();
            final bTime = (b['created_at'] as Timestamp?) ?? Timestamp.now();
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }
}
