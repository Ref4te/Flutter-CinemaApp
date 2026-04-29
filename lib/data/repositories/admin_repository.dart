import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/movie.dart';
import '../../domain/entities/session.dart';
import 'tmdb_repository.dart';

class AdminRepository {
  AdminRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    TmdbRepository? tmdbRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _tmdbRepository = tmdbRepository ?? TmdbRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TmdbRepository _tmdbRepository;

  bool get isAdmin => _auth.currentUser?.email == 'manat11@mail.ru';

  Future<void> recreateGeneratedData() async {
    _ensureAdmin();

    await _deleteCollection('sessions');
    await _deleteCollection('tickets');
    await _deleteCollection('global_schedule');

    final homeData = await _tmdbRepository.loadHomeData();
    final movies = homeData.movies.toList()..shuffle();
    final selectedMovies = movies.take(25).toList();
    if (selectedMovies.isEmpty) return;

    final cinemas = await _loadCinemaConfigs();
    if (cinemas.isEmpty) {
      await _createDefaultCinemas();
      return recreateGeneratedData();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final random = Random();
    final batch = _firestore.batch();

    for (final cinema in cinemas) {
      final halls = await cinema.reference.collection('halls').get();
      if (halls.docs.isEmpty) continue;

      for (final hallDoc in halls.docs) {
        DateTime currentTime = today.add(const Duration(hours: 10));
        final dayEnd = today.add(const Duration(hours: 24));
        int lastMovieId = -1;

        while (currentTime.add(const Duration(minutes: 60)).isBefore(dayEnd)) {
          var candidates = selectedMovies.where((m) => m.id != lastMovieId).toList();
          if (candidates.isEmpty) candidates = selectedMovies;

          final movie = candidates[random.nextInt(candidates.length)];
          lastMovieId = movie.id;
          final duration = _parseDuration(movie.duration);
          final end = currentTime.add(Duration(minutes: duration));
          if (end.isAfter(dayEnd)) break;

          final hallData = hallDoc.data();
          final seats = _buildSeatsFromHallData(hallData);

          final ref = _firestore.collection('sessions').doc();
          batch.set(ref, {
            'movieId': movie.id,
            'movieTitle': movie.title,
            'startTime': Timestamp.fromDate(currentTime),
            'endTime': Timestamp.fromDate(end),
            'cinemaName': cinema.data()['name'],
            'cinemaId': cinema.id,
            'cinemaAddress': cinema.data()['address'],
            'hallId': _extractHallNumber(hallData['name']?.toString() ?? hallDoc.id),
            'hallDocId': hallDoc.id,
            'hallName': hallData['name'] ?? hallDoc.id,
            'seats': seats.map((e) => e.toMap()).toList(),
          });

          final cleanupMinutes = 20;
          currentTime = end.add(Duration(minutes: cleanupMinutes));
        }
      }
    }

    await batch.commit();
  }

  Future<void> createCinema({required String name, required String address}) async {
    _ensureAdmin();
    await _firestore.collection('cinemas').add({
      'name': name,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCinema(String cinemaId) async {
    _ensureAdmin();
    final ref = _firestore.collection('cinemas').doc(cinemaId);
    final halls = await ref.collection('halls').get();
    for (final hall in halls.docs) {
      await hall.reference.delete();
    }
    await ref.delete();
  }

  Future<void> addHall({
    required String cinemaId,
    required String name,
    required int rows,
    required int cols,
    required List<int> vipRows,
  }) async {
    _ensureAdmin();
    await _firestore.collection('cinemas').doc(cinemaId).collection('halls').add({
      'name': name,
      'rows': rows,
      'cols': cols,
      'vipRows': vipRows,
      'layout': _emptyLayout(rows: rows, cols: cols),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHallLayout({
    required String cinemaId,
    required String hallId,
    required int rows,
    required int cols,
    required List<Map<String, dynamic>> layout,
  }) async {
    _ensureAdmin();
    await _firestore.collection('cinemas').doc(cinemaId).collection('halls').doc(hallId).update({
      'rows': rows,
      'cols': cols,
      'layout': layout,
      'vipRows': const <int>[],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteHall({required String cinemaId, required String hallId}) async {
    _ensureAdmin();
    await _firestore.collection('cinemas').doc(cinemaId).collection('halls').doc(hallId).delete();
  }

  Future<List<MovieItem>> loadMovies() async {
    final homeData = await _tmdbRepository.loadHomeData();
    return homeData.movies;
  }

  Future<void> applyScheduleForMovie({
    required MovieItem movie,
    required List<HallRef> halls,
    required int baseHour,
    int startHour = 10,
    int endHour = 24,
    int cleanupMinutes = 20,
  }) async {
    _ensureAdmin();
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final duration = _parseDuration(movie.duration);

    final batch = _firestore.batch();

    for (final hall in halls) {
      DateTime currentStart = day.add(Duration(hours: baseHour));
      while (true) {
        final end = currentStart.add(Duration(minutes: duration));
        if (end.hour >= endHour && end.minute > 0) break;

        final seats = _buildSeatsFromRef(hall);
        final sessionRef = _firestore.collection('sessions').doc();
        batch.set(sessionRef, {
          'movieId': movie.id,
          'movieTitle': movie.title,
          'startTime': Timestamp.fromDate(currentStart),
          'endTime': Timestamp.fromDate(end),
          'cinemaName': hall.cinemaName,
          'cinemaId': hall.cinemaId,
          'cinemaAddress': hall.cinemaAddress,
          'hallId': _extractHallNumber(hall.hallName),
          'hallDocId': hall.hallId,
          'hallName': hall.hallName,
          'seats': seats.map((e) => e.toMap()).toList(),
        });

        final scheduleRef = _firestore.collection('global_schedule').doc();
        batch.set(scheduleRef, {
          'movieId': movie.id,
          'movieTitle': movie.title,
          'cinemaId': hall.cinemaId,
          'cinemaName': hall.cinemaName,
          'hallId': _extractHallNumber(hall.hallName),
          'hallDocId': hall.hallId,
          'hallName': hall.hallName,
          'startTime': Timestamp.fromDate(currentStart),
          'endTime': Timestamp.fromDate(end),
          'generatedAt': FieldValue.serverTimestamp(),
        });

        currentStart = end.add(Duration(minutes: cleanupMinutes));
        if (currentStart.hour < startHour || currentStart.hour >= endHour) {
          break;
        }
      }
    }

    await batch.commit();
  }


  Future<MovieMeta> loadMovieMeta(int movieId, String fallbackDuration) async {
    try {
      final details = await _tmdbRepository.loadMovieFullDetails(movieId);
      final runtime = details.runtimeMinutes > 0 ? details.runtimeMinutes : _parseDuration(fallbackDuration);
      return MovieMeta(
        durationMinutes: runtime,
        ageRating: details.ageRating?.trim().isNotEmpty == true ? details.ageRating!.trim() : '16+',
      );
    } catch (_) {
      return MovieMeta(
        durationMinutes: _parseDuration(fallbackDuration),
        ageRating: '16+',
      );
    }
  }

  Future<List<ExistingSessionSlot>> loadExistingHallSlots({
    required String cinemaId,
    required String hallId,
  }) async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('global_schedule')
        .where('hallId', isEqualTo: hallId)
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final start = (data['startTime'] as Timestamp?)?.toDate();
          return data['cinemaId'] == cinemaId && start != null && !start.isBefore(dayStart) && start.isBefore(dayEnd);
        })
        .map((doc) {
          final data = doc.data();
          return ExistingSessionSlot(
            id: doc.id,
            movieId: (data['movieId'] as num?)?.toInt() ?? 0,
            start: (data['startTime'] as Timestamp).toDate(),
            end: (data['endTime'] as Timestamp).toDate(),
          );
        })
        .toList();
  }

  Future<void> saveMovieScheduleForHall({
    required MovieItem movie,
    required HallRef hall,
    required List<DateTime> starts,
    required SessionPrices prices,
    int cleanupMinutes = 20,
  }) async {
    _ensureAdmin();

    final meta = await loadMovieMeta(movie.id, movie.duration);
    final duration = meta.durationMinutes;
    final seats = _buildSeatsFromRef(hall);

    final oldSessions = await _firestore
        .collection('sessions')
        .where('movieId', isEqualTo: movie.id)
        .where('cinemaId', isEqualTo: hall.cinemaId)
        .where('hallId', isEqualTo: hall.hallId)
        .get();
    final oldGlobal = await _firestore
        .collection('global_schedule')
        .where('movieId', isEqualTo: movie.id)
        .where('cinemaId', isEqualTo: hall.cinemaId)
        .where('hallId', isEqualTo: hall.hallId)
        .get();

    final batch = _firestore.batch();
    for (final doc in oldSessions.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in oldGlobal.docs) {
      batch.delete(doc.reference);
    }

    final sortedStarts = starts.toList()..sort();
    for (final start in sortedStarts) {
      final end = start.add(Duration(minutes: duration));
      final sessionRef = _firestore.collection('sessions').doc();
      batch.set(sessionRef, {
        'movieId': movie.id,
        'movieTitle': movie.title,
        'startTime': Timestamp.fromDate(start),
        'endTime': Timestamp.fromDate(end),
        'cinemaName': hall.cinemaName,
        'cinemaId': hall.cinemaId,
        'cinemaAddress': hall.cinemaAddress,
        'hallId': _extractHallNumber(hall.hallName),
        'hallDocId': hall.hallId,
        'hallName': hall.hallName,
        'cleanupMinutes': cleanupMinutes,
        'prices': prices.toMap(),
        'seats': seats.map((e) => e.toMap()).toList(),
      });

      final scheduleRef = _firestore.collection('global_schedule').doc();
      batch.set(scheduleRef, {
        'movieId': movie.id,
        'movieTitle': movie.title,
        'cinemaId': hall.cinemaId,
        'cinemaName': hall.cinemaName,
        'hallId': _extractHallNumber(hall.hallName),
        'hallDocId': hall.hallId,
        'hallName': hall.hallName,
        'startTime': Timestamp.fromDate(start),
        'endTime': Timestamp.fromDate(end),
        'generatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }


  Future<void> clearMovieScheduleForDate({
    required int movieId,
    required DateTime date,
  }) async {
    _ensureAdmin();
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final sessions = await _firestore.collection('sessions').where('movieId', isEqualTo: movieId).get();
    final global = await _firestore.collection('global_schedule').where('movieId', isEqualTo: movieId).get();

    final batch = _firestore.batch();
    for (final doc in sessions.docs) {
      final start = (doc.data()['startTime'] as Timestamp?)?.toDate();
      if (start != null && !start.isBefore(dayStart) && start.isBefore(dayEnd)) {
        batch.delete(doc.reference);
      }
    }
    for (final doc in global.docs) {
      final start = (doc.data()['startTime'] as Timestamp?)?.toDate();
      if (start != null && !start.isBefore(dayStart) && start.isBefore(dayEnd)) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future<void> clearMovieSchedule(int movieId) async {
    _ensureAdmin();

    final sessions = await _firestore.collection('sessions').where('movieId', isEqualTo: movieId).get();
    final schedule = await _firestore.collection('global_schedule').where('movieId', isEqualTo: movieId).get();

    final batch = _firestore.batch();
    for (final doc in sessions.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in schedule.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> cinemasStream() {
    return _firestore.collection('cinemas').orderBy('createdAt', descending: false).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> hallsStream(String cinemaId) {
    return _firestore.collection('cinemas').doc(cinemaId).collection('halls').orderBy('createdAt').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> movieScheduleStream(int movieId) {
    return _firestore
        .collection('global_schedule')
        .where('movieId', isEqualTo: movieId)
        .orderBy('startTime')
        .snapshots();
  }

  Future<void> _createDefaultCinemas() async {
    final items = [
      {'name': 'Kinopark 8 Saryarka', 'address': 'пр. Туран, 24'},
      {'name': 'Chaplin Khan Shatyr', 'address': 'пр. Туран, 37'},
      {'name': 'Keruen Cinema', 'address': 'ул. Достык, 9'},
    ];
    for (final cinema in items) {
      final ref = await _firestore.collection('cinemas').add({
        'name': cinema['name'],
        'address': cinema['address'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (int i = 1; i <= 3; i++) {
        await ref.collection('halls').add({
          'name': 'Зал $i',
          'rows': 12,
          'cols': 12,
          'vipRows': const <int>[],
          'layout': _emptyLayout(rows: 12, cols: 12),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadCinemaConfigs() async {
    final snapshot = await _firestore.collection('cinemas').get();
    return snapshot.docs;
  }

  void _ensureAdmin() {
    if (!isAdmin) {
      throw StateError('Доступ только для администратора');
    }
  }

  List<Seat> _buildSeatsFromRef(HallRef hall) {
    if (hall.layout.isNotEmpty) {
      return hall.layout
          .where((item) => item.isEnabled)
          .map(
            (item) => Seat(
              id: 'r${item.row}c${item.col}',
              row: item.row,
              column: item.col,
              isAvailable: true,
              isVip: item.isVip,
            ),
          )
          .toList();
    }

    return _generateSeats(rows: hall.rows, cols: hall.cols, vipRows: hall.vipRows);
  }

  List<Seat> _buildSeatsFromHallData(Map<String, dynamic> hallData) {
    final layoutRaw = hallData['layout'] as List<dynamic>?;
    if (layoutRaw != null && layoutRaw.isNotEmpty) {
      return layoutRaw
          .cast<Map<String, dynamic>>()
          .where((item) => item['isEnabled'] == true)
          .map(
            (item) => Seat(
              id: 'r${item['row']}c${item['col']}',
              row: (item['row'] as num).toInt(),
              column: (item['col'] as num).toInt(),
              isAvailable: true,
              isVip: item['isVip'] == true,
            ),
          )
          .toList();
    }

    final rows = (hallData['rows'] as num?)?.toInt() ?? 6;
    final cols = (hallData['cols'] as num?)?.toInt() ?? 10;
    final vipRows = List<int>.from(hallData['vipRows'] as List<dynamic>? ?? const [4, 5]);
    return _generateSeats(rows: rows, cols: cols, vipRows: vipRows);
  }

  List<SeatLayoutCell> mapLayout(List<dynamic>? raw, {required int rows, required int cols}) {
    if (raw == null || raw.isEmpty) {
      return List.generate(rows * cols, (index) {
        final row = index ~/ cols + 1;
        final col = index % cols + 1;
        return SeatLayoutCell(row: row, col: col, isEnabled: false, isVip: false);
      });
    }

    return raw
        .cast<Map<String, dynamic>>()
        .map(
          (item) => SeatLayoutCell(
            row: (item['row'] as num).toInt(),
            col: (item['col'] as num).toInt(),
            isEnabled: item['isEnabled'] == true,
            isVip: item['isVip'] == true,
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>> _emptyLayout({required int rows, required int cols}) {
    return List.generate(rows * cols, (index) {
      final row = index ~/ cols + 1;
      final col = index % cols + 1;
      return {
        'row': row,
        'col': col,
        'isEnabled': false,
        'isVip': false,
      };
    });
  }

  List<Seat> _generateSeats({required int rows, required int cols, required List<int> vipRows}) {
    final seats = <Seat>[];
    for (int row = 1; row <= rows; row++) {
      for (int col = 1; col <= cols; col++) {
        seats.add(
          Seat(
            id: 'r${row}c$col',
            row: row,
            column: col,
            isAvailable: true,
            isVip: vipRows.contains(row),
          ),
        );
      }
    }
    return seats;
  }

  Future<void> _deleteCollection(String name) async {
    final snapshot = await _firestore.collection(name).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  int _extractHallNumber(String source) {
    final match = RegExp(r'(\d+)').firstMatch(source);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 1;
    }
    return 1;
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
}

class HallRef {
  const HallRef({
    required this.cinemaId,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.hallId,
    required this.hallName,
    required this.rows,
    required this.cols,
    required this.vipRows,
    required this.layout,
  });

  final String cinemaId;
  final String cinemaName;
  final String cinemaAddress;
  final String hallId;
  final String hallName;
  final int rows;
  final int cols;
  final List<int> vipRows;
  final List<SeatLayoutCell> layout;
}

class SeatLayoutCell {
  const SeatLayoutCell({
    required this.row,
    required this.col,
    required this.isEnabled,
    required this.isVip,
  });

  final int row;
  final int col;
  final bool isEnabled;
  final bool isVip;

  SeatLayoutCell copyWith({bool? isEnabled, bool? isVip}) {
    return SeatLayoutCell(
      row: row,
      col: col,
      isEnabled: isEnabled ?? this.isEnabled,
      isVip: isVip ?? this.isVip,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'row': row,
      'col': col,
      'isEnabled': isEnabled,
      'isVip': isVip,
    };
  }
}


class MovieMeta {
  const MovieMeta({required this.durationMinutes, required this.ageRating});

  final int durationMinutes;
  final String ageRating;
}

class ExistingSessionSlot {
  const ExistingSessionSlot({
    required this.id,
    required this.movieId,
    required this.start,
    required this.end,
  });

  final String id;
  final int movieId;
  final DateTime start;
  final DateTime end;
}

class SessionPrices {
  const SessionPrices({
    required this.adult,
    required this.student,
    required this.child,
    required this.vip,
  });

  final int adult;
  final int student;
  final int child;
  final int vip;

  Map<String, dynamic> toMap() {
    return {
      'adult': adult,
      'student': student,
      'child': child,
      'vip': vip,
    };
  }
}
