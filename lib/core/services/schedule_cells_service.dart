import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/repositories/admin_repository.dart';

class ScheduleCellsService {
  ScheduleCellsService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int defaultSlots = 15;

  String dateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> ensureGrid({required DateTime date, required List<HallRef> halls}) async {
    final key = dateKey(date);
    final col = _firestore.collection('schedule_cells');

    final existing = await col.where('dateKey', isEqualTo: key).get();
    final existingIds = existing.docs.map((d) => d.id).toSet();

    final batch = _firestore.batch();
    for (final hall in halls) {
      for (int i = 0; i < defaultSlots; i++) {
        final docId = '${key}_${hall.cinemaId}_${hall.hallId}_$i';
        if (existingIds.contains(docId)) continue;
        final ref = col.doc(docId);
        final dayStart = DateTime(date.year, date.month, date.day);
        final initialTime = dayStart.add(Duration(hours: 10 + i));
        batch.set(ref, {
          'dateKey': key,
          'cinemaId': hall.cinemaId,
          'cinemaName': hall.cinemaName,
          'hallId': hall.hallId,
          'hallName': hall.hallName,
          'slotIndex': i,
          'startTime': Timestamp.fromDate(initialTime),
          'movieId': null,
          'movieTitle': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<List<ScheduleCellItem>> loadGrid(DateTime date) async {
    final key = dateKey(date);
    final snap = await _firestore.collection('schedule_cells').where('dateKey', isEqualTo: key).get();
    return snap.docs.map((d) => ScheduleCellItem.fromDoc(d)).toList();
  }

  Future<void> saveGrid(List<ScheduleCellItem> cells) async {
    final batch = _firestore.batch();
    for (final cell in cells) {
      final ref = _firestore.collection('schedule_cells').doc(cell.id);
      batch.set(ref, cell.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}

class ScheduleCellItem {
  const ScheduleCellItem({
    required this.id,
    required this.dateKey,
    required this.cinemaId,
    required this.cinemaName,
    required this.hallId,
    required this.hallName,
    required this.slotIndex,
    required this.startTime,
    required this.movieId,
    required this.movieTitle,
  });

  final String id;
  final String dateKey;
  final String cinemaId;
  final String cinemaName;
  final String hallId;
  final String hallName;
  final int slotIndex;
  final DateTime startTime;
  final int? movieId;
  final String? movieTitle;

  bool get isFree => movieId == null;

  ScheduleCellItem copyWith({DateTime? startTime, int? movieId, String? movieTitle, bool clearMovie = false}) {
    return ScheduleCellItem(
      id: id,
      dateKey: dateKey,
      cinemaId: cinemaId,
      cinemaName: cinemaName,
      hallId: hallId,
      hallName: hallName,
      slotIndex: slotIndex,
      startTime: startTime ?? this.startTime,
      movieId: clearMovie ? null : (movieId ?? this.movieId),
      movieTitle: clearMovie ? null : (movieTitle ?? this.movieTitle),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'cinemaId': cinemaId,
      'cinemaName': cinemaName,
      'hallId': hallId,
      'hallName': hallName,
      'slotIndex': slotIndex,
      'startTime': Timestamp.fromDate(startTime),
      'movieId': movieId,
      'movieTitle': movieTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ScheduleCellItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ScheduleCellItem(
      id: doc.id,
      dateKey: data['dateKey']?.toString() ?? '',
      cinemaId: data['cinemaId']?.toString() ?? '',
      cinemaName: data['cinemaName']?.toString() ?? '',
      hallId: data['hallId']?.toString() ?? '',
      hallName: data['hallName']?.toString() ?? '',
      slotIndex: (data['slotIndex'] as num?)?.toInt() ?? 0,
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      movieId: (data['movieId'] as num?)?.toInt(),
      movieTitle: data['movieTitle']?.toString(),
    );
  }
}
