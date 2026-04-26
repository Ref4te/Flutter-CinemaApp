import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис, который поддерживает окно расписания на 3 дня для фильмов
/// из категории «Сейчас в кино».
class FirestoreSessionScheduleService {
  FirestoreSessionScheduleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<String> _defaultTimeSlots = <String>[
    '10:00',
    '13:00',
    '16:00',
    '19:00',
    '22:00',
  ];

  static const Map<String, int> _defaultTicketPrices = <String, int>{
    'adult': 2500,
    'child': 1500,
    'student': 1800,
    'vip': 5000,
  };

  /// Создает/обновляет расписание на 3 дня вперед для фильмов «Сейчас в кино».
  ///
  /// Что делает метод:
  /// 1) удаляет «первый день» (все прошедшие сеансы);
  /// 2) чистит сеансы за пределами окна [сегодня, сегодня+2];
  /// 3) добавляет недостающие сеансы, чтобы в базе всегда было ровно 3 дня.
  ///
  /// В коллекции `movies` ожидается булево поле `is_now_showing`.
  /// Если такого поля нет, можно передать [nowShowingMovieIds] вручную.
  Future<void> rollNowPlayingScheduleWindow({
    DateTime? now,
    List<String>? nowShowingMovieIds,
    List<String> timeSlots = _defaultTimeSlots,
  }) async {
    final DateTime today = _startOfDay(now ?? DateTime.now());
    final DateTime windowEndExclusive = today.add(const Duration(days: 3));

    final QuerySnapshot<Map<String, dynamic>> hallsSnapshot =
        await _firestore.collection('halls').get();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> hallDocs =
        hallsSnapshot.docs;

    if (hallDocs.isEmpty) {
      return;
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> movieDocs;

    if (nowShowingMovieIds != null && nowShowingMovieIds.isNotEmpty) {
      movieDocs = await _loadMoviesByIds(nowShowingMovieIds);
    } else {
      final QuerySnapshot<Map<String, dynamic>> nowShowingSnapshot =
          await _firestore
              .collection('movies')
              .where('is_now_showing', isEqualTo: true)
              .get();
      movieDocs = nowShowingSnapshot.docs;
    }

    if (movieDocs.isEmpty) {
      return;
    }

    final Set<String> movieIds = movieDocs.map((doc) => doc.id).toSet();

    final QuerySnapshot<Map<String, dynamic>> sessionsSnapshot =
        await _firestore
            .collection('sessions')
            .where('movie_id', whereIn: movieIds.toList())
            .get();

    final WriteBatch cleanupBatch = _firestore.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> session
        in sessionsSnapshot.docs) {
      final Timestamp? ts = session.data()['date'] as Timestamp?;
      if (ts == null) {
        continue;
      }

      final DateTime date = _startOfDay(ts.toDate());
      final bool outOfWindow =
          date.isBefore(today) || !date.isBefore(windowEndExclusive);
      if (outOfWindow) {
        cleanupBatch.delete(session.reference);
      }
    }
    await cleanupBatch.commit();

    final WriteBatch upsertBatch = _firestore.batch();

    for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
      final DateTime targetDate = today.add(Duration(days: dayOffset));

      for (final movie in movieDocs) {
        final Map<String, dynamic> movieData = movie.data();
        final String movieTitle = (movieData['title'] as String?)?.trim().isNotEmpty == true
            ? (movieData['title'] as String)
            : 'Без названия';

        for (final hall in hallDocs) {
          final Map<String, dynamic> hallData = hall.data();
          final String hallName = (hallData['name'] as String?)?.trim().isNotEmpty == true
              ? (hallData['name'] as String)
              : 'Зал';

          for (final String time in timeSlots) {
            final DocumentReference<Map<String, dynamic>> sessionRef = _firestore
                .collection('sessions')
                .doc(_buildSessionId(
                  movieId: movie.id,
                  hallId: hall.id,
                  date: targetDate,
                  time: time,
                ));

            upsertBatch.set(sessionRef, {
              'movie_id': movie.id,
              'movie_title': movieTitle,
              'hall_id': hall.id,
              'hall_name': hallName,
              'age_rating': movieData['age_rating'] ?? '16+',
              'date': Timestamp.fromDate(_mergeDateAndTime(targetDate, time)),
              'time': time,
              'ticket_prices': _defaultTicketPrices,
              'booked_seats': const <String>[],
              'updated_at': FieldValue.serverTimestamp(),
              'created_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }
    }

    await upsertBatch.commit();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadMoviesByIds(
    List<String> ids,
  ) async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
        <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (int i = 0; i < ids.length; i += 10) {
      final List<String> chunk = ids.sublist(
        i,
        (i + 10 > ids.length) ? ids.length : i + 10,
      );
      final QuerySnapshot<Map<String, dynamic>> chunkSnapshot =
          await _firestore
              .collection('movies')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
      docs.addAll(chunkSnapshot.docs);
    }

    return docs;
  }

  DateTime _mergeDateAndTime(DateTime date, String time) {
    final List<String> parts = time.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  String _buildSessionId({
    required String movieId,
    required String hallId,
    required DateTime date,
    required String time,
  }) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    final String normalizedTime = time.replaceAll(':', '');

    return '${movieId}_${hallId}_${y}${m}${d}_$normalizedTime';
  }
}
