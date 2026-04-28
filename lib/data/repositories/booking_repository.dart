import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/movie.dart';
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
    final movies = _buildMovieSlots(homeData.movies);
    if (movies.length < 24) return;

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
      ).add(const Duration(days: 1));

      for (int cinemaIndex = 0; cinemaIndex < _cinemas.length; cinemaIndex++) {
        final cinema = _cinemas[cinemaIndex];
        final cinemaMovies = movies.skip(cinemaIndex * 8).take(8).toList();

        for (int hallId = 1; hallId <= cinema.halls.length; hallId++) {
          final hall = cinema.halls[hallId - 1];
          final hallMovies = cinemaMovies
              .where((movie) => hall.canPlay(movie.popularity))
              .toList()
            ..shuffle(random);
          int hallCursor = 0;

          DateTime currentTime = dayStart;
          int lastMovieId = -1;

          while (currentTime.isBefore(dayEnd)) {
            if (currentTime.isBefore(now)) {
              currentTime = currentTime.add(const Duration(minutes: 20));
              continue;
            }

            final slotPopularity = _timePopularity(currentTime.hour);
            if (hallMovies.isEmpty) break;
            final timeFilteredMovies = hallMovies.where((movie) {
              if (movie.isKids && currentTime.hour >= 17) return false;
              if (movie.isAdult && currentTime.hour < 22) return false;
              return true;
            }).toList();

            if (timeFilteredMovies.isEmpty) {
              currentTime = currentTime.add(const Duration(minutes: 20));
              continue;
            }

            _MovieSlot pickMovie({required bool strictPopularity}) {
              for (int i = 0; i < timeFilteredMovies.length; i++) {
                final candidate = timeFilteredMovies[
                    (hallCursor + i) % timeFilteredMovies.length];
                final matchesPopularity =
                    !strictPopularity || candidate.popularity == slotPopularity;
                final isNotRepeat = candidate.tmdbId != lastMovieId;
                if (matchesPopularity && isNotRepeat) {
                  hallCursor = (hallCursor + i + 1) % timeFilteredMovies.length;
                  return candidate;
                }
              }
              final fallback =
                  timeFilteredMovies[hallCursor % timeFilteredMovies.length];
              hallCursor = (hallCursor + 1) % timeFilteredMovies.length;
              return fallback;
            }

            final movie = pickMovie(strictPopularity: true);
            lastMovieId = movie.tmdbId;

            final duration = movie.runtimeMinutes;
            final sessionEndTime = currentTime.add(Duration(minutes: duration));
            if (sessionEndTime.isAfter(dayEnd)) {
              break;
            }

            final seats = _generateSeatsFromHall(hall);

            operations.add((
              ref: _firestore.collection('sessions').doc(),
              data: {
                'movieId': movie.tmdbId,
                'movieTitle': movie.title,
                'startTime': Timestamp.fromDate(currentTime),
                'endTime': Timestamp.fromDate(sessionEndTime),
                'cinemaName': cinema.name,
                'hallId': hallId,
                'hallName': hall.name,
                'hallType': hall.type.name,
                'runtimeMinutes': movie.runtimeMinutes,
                'popularity': movie.popularity,
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

  List<_MovieSlot> _buildMovieSlots(List<MovieItem> movies) {
    final slots = movies
        .map(
          (movie) => _MovieSlot(
            tmdbId: movie.id,
            title: movie.title,
            runtimeMinutes: _parseDuration(movie.duration),
            popularity: movie.rating >= 7.2
                ? 1
                : movie.rating >= 6.0
                    ? 2
                    : 3,
            isKids: _isKidsMovie(movie),
            isAdult: movie.isAdult,
          ),
        )
        .where((slot) => slot.runtimeMinutes > 30)
        .toList()
      ..sort((a, b) => a.popularity.compareTo(b.popularity));

    final unique = <int, _MovieSlot>{
      for (final movie in slots) movie.tmdbId: movie,
    };
    for (final fallback in _fallbackMovies) {
      unique.putIfAbsent(fallback.tmdbId, () => fallback);
    }
    return unique.values.take(24).toList();
  }

  bool _isKidsMovie(MovieItem movie) {
    final text = '${movie.category} ${movie.title} ${movie.description}'
        .toLowerCase();
    return text.contains('animation') ||
        text.contains('family') ||
        text.contains('kids') ||
        text.contains('дет') ||
        text.contains('мульт') ||
        text.contains('семейн');
  }

  int _timePopularity(int hour) {
    if (hour >= 18 && hour <= 22) return 1;
    if (hour >= 12 && hour <= 17) return 2;
    return 3;
  }

  List<Seat> _generateSeatsFromHall(_Hall hall) {
    final seats = <Seat>[];
    final vipStartRow = (hall.rows * 0.6).floor().clamp(1, hall.rows);

    for (int row = 1; row <= hall.rows; row++) {
      for (int col = 1; col <= hall.seatsPerRow; col++) {
        final center = hall.seatsPerRow / 2;
        final isCenterSeat = (col - center).abs() <= 1.5;
        final isVipByRow = row >= vipStartRow;
        final isVip = hall.type == _HallType.vip ||
            (hall.type == _HallType.imax && isCenterSeat) ||
            (hall.type == _HallType.comfort && isVipByRow && isCenterSeat) ||
            (hall.type == _HallType.standard && isVipByRow && isCenterSeat);

        seats.add(
          Seat(
            id: 'r${row}c$col',
            row: row,
            column: col,
            isAvailable: true,
            isVip: isVip,
          ),
        );
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

class _Cinema {
  const _Cinema({required this.name, required this.halls});

  final String name;
  final List<_Hall> halls;
}

class _Hall {
  const _Hall({
    required this.name,
    required this.type,
    required this.rows,
    required this.seatsPerRow,
  });

  final String name;
  final _HallType type;
  final int rows;
  final int seatsPerRow;

  bool canPlay(int popularity) {
    if (type == _HallType.imax || type == _HallType.vip) {
      return popularity <= 2;
    }
    return true;
  }
}

enum _HallType { standard, comfort, vip, imax }

class _MovieSlot {
  const _MovieSlot({
    required this.tmdbId,
    required this.title,
    required this.runtimeMinutes,
    required this.popularity,
    required this.isKids,
    required this.isAdult,
  });

  final int tmdbId;
  final String title;
  final int runtimeMinutes;
  final int popularity;
  final bool isKids;
  final bool isAdult;
}

const List<_Cinema> _cinemas = [
  _Cinema(
    name: 'Синема Парк',
    halls: [
      _Hall(name: 'IMAX', type: _HallType.imax, rows: 12, seatsPerRow: 14),
      _Hall(name: 'Зал VIP', type: _HallType.vip, rows: 6, seatsPerRow: 8),
      _Hall(name: 'Комфорт', type: _HallType.comfort, rows: 10, seatsPerRow: 12),
      _Hall(name: 'Зал 4', type: _HallType.standard, rows: 10, seatsPerRow: 12),
    ],
  ),
  _Cinema(
    name: 'Мегаплекс',
    halls: [
      _Hall(name: 'Dolby Atmos', type: _HallType.imax, rows: 11, seatsPerRow: 13),
      _Hall(name: 'Комфорт', type: _HallType.comfort, rows: 8, seatsPerRow: 10),
      _Hall(name: 'Зал 3', type: _HallType.standard, rows: 10, seatsPerRow: 12),
      _Hall(name: 'Зал 4', type: _HallType.standard, rows: 10, seatsPerRow: 12),
    ],
  ),
  _Cinema(
    name: 'Kinomax',
    halls: [
      _Hall(name: '4DX', type: _HallType.vip, rows: 8, seatsPerRow: 10),
      _Hall(name: 'Premium', type: _HallType.comfort, rows: 7, seatsPerRow: 9),
      _Hall(name: 'Зал 3', type: _HallType.standard, rows: 10, seatsPerRow: 12),
      _Hall(name: 'Зал 4', type: _HallType.standard, rows: 10, seatsPerRow: 12),
    ],
  ),
];

const List<_MovieSlot> _fallbackMovies = [
  _MovieSlot(tmdbId: 550, title: 'Бойцовский клуб', runtimeMinutes: 139, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 27205, title: 'Начало', runtimeMinutes: 148, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 157336, title: 'Интерстеллар', runtimeMinutes: 169, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 299534, title: 'Мстители: Финал', runtimeMinutes: 181, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 76341, title: 'Безумный Макс', runtimeMinutes: 120, popularity: 2, isKids: false, isAdult: true),
  _MovieSlot(tmdbId: 475557, title: 'Джокер', runtimeMinutes: 122, popularity: 2, isKids: false, isAdult: true),
  _MovieSlot(tmdbId: 496243, title: 'Паразиты', runtimeMinutes: 132, popularity: 2, isKids: false, isAdult: true),
  _MovieSlot(tmdbId: 13, title: 'Форрест Гамп', runtimeMinutes: 142, popularity: 3, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 862, title: 'История игрушек', runtimeMinutes: 81, popularity: 2, isKids: true, isAdult: false),
  _MovieSlot(tmdbId: 12, title: 'В поисках Немо', runtimeMinutes: 100, popularity: 2, isKids: true, isAdult: false),
  _MovieSlot(tmdbId: 278, title: 'Побег из Шоушенка', runtimeMinutes: 142, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 424, title: 'Список Шиндлера', runtimeMinutes: 195, popularity: 1, isKids: false, isAdult: true),
  _MovieSlot(tmdbId: 680, title: 'Криминальное чтиво', runtimeMinutes: 154, popularity: 1, isKids: false, isAdult: true),
  _MovieSlot(tmdbId: 155, title: 'Темный рыцарь', runtimeMinutes: 152, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 238, title: 'Крёстный отец', runtimeMinutes: 175, popularity: 1, isKids: false, isAdult: true),
  _MovieSlot(tmdbId: 497, title: 'Зеленая миля', runtimeMinutes: 189, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 122, title: 'Властелин колец', runtimeMinutes: 178, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 603, title: 'Матрица', runtimeMinutes: 136, popularity: 1, isKids: false, isAdult: true),
  _MovieSlot(tmdbId: 673, title: 'Гарри Поттер', runtimeMinutes: 152, popularity: 2, isKids: true, isAdult: false),
  _MovieSlot(tmdbId: 120, title: 'ВК: Братство кольца', runtimeMinutes: 178, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 11, title: 'Звездные войны', runtimeMinutes: 121, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 1891, title: 'Империя наносит ответный удар', runtimeMinutes: 124, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 1892, title: 'Возвращение джедая', runtimeMinutes: 131, popularity: 1, isKids: false, isAdult: false),
  _MovieSlot(tmdbId: 10195, title: 'Тор', runtimeMinutes: 115, popularity: 2, isKids: false, isAdult: false),
];
