import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/schedule_item.dart';
import '../models/preset.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  FirestoreService({required this.userId});

  CollectionReference get schedules => _db.collection('users').doc(userId).collection('schedules');
  CollectionReference get presets => _db.collection('users').doc(userId).collection('presets');

  // helper: convert local date+time to UTC DateTime for notifyAtUtc
  DateTime localDateTimeToUtc(String date, String time) {
    // date: YYYY-MM-DD, time: HH:mm
    final dt = DateTime.parse('$date' + 'T' + '${time}:00');
    return dt.toUtc();
  }

  Future<List<ScheduleItem>> getSchedulesForDate(String date) async {
    final q = await schedules.where('date', isEqualTo: date).where('deletedAt', isNull: true).get();
    return q.docs.map((d) => ScheduleItem.fromDoc(d)).toList();
  }

  Future<void> addOrUpdateSchedule(ScheduleItem item) async {
    final data = item.toMap();
    if (item.id.isEmpty) {
      data['createdAt'] = Timestamp.now();
      await schedules.add(data);
    } else {
      await schedules.doc(item.id).set(data);
    }
  }

  Future<void> deleteScheduleSoft(String id) async {
    await schedules.doc(id).update({'deletedAt': Timestamp.now()});
  }

  Future<void> toggleDisable(String id, bool disabled) async {
    await schedules.doc(id).update({'disabled': disabled});
  }

  Future<void> applyPresetToDate(String presetId, String date) async {
    final snap = await presets.doc(presetId).get();
    if (!snap.exists) return;
    final p = Preset.fromDoc(snap);
    // For each preset item, insert or overwrite by title for the date
    for (final it in p.items) {
      // check existing doc with same title & date
      final q = await schedules.where('date', isEqualTo: date).where('title', isEqualTo: it.title).get();
      final notifyAtUtc = localDateTimeToUtc(date, it.notifyTime);
      final map = {
        'title': it.title,
        'date': date,
        'notifyTime': it.notifyTime,
        'notifyAtUtc': Timestamp.fromDate(notifyAtUtc),
        'lineMessage': it.lineMessage,
        'memo': it.memo,
        'disabled': it.disabled,
        'presetSourceId': presetId,
        'createdAt': Timestamp.now(),
        'deletedAt': null,
      };
      if (q.docs.isNotEmpty) {
        await schedules.doc(q.docs.first.id).set(map);
      } else {
        await schedules.add(map);
      }
    }
  }

  // Remove all schedules that were created by a preset with presetId for a given date
  Future<void> removePresetFromDate(String presetId, String date) async {
    final q = await schedules.where('date', isEqualTo: date).where('presetSourceId', isEqualTo: presetId).get();
    for (final d in q.docs) {
      await schedules.doc(d.id).update({'deletedAt': Timestamp.now()});
    }
  }

  Future<List<Preset>> listPresets() async {
    final q = await presets.where('deletedAt', isNull: true).get();
    return q.docs.map((d) => Preset.fromDoc(d)).toList();
  }

  Future<void> createPreset(String name, List<PresetItem> items) async {
    await presets.add({
      'name': name,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.now(),
      'deletedAt': null,
    });
  }

  Future<void> softDeletePreset(String presetId) async {
    await presets.doc(presetId).update({'deletedAt': Timestamp.now()});
  }

  // Cleanup older schedules (e.g., older than daysAgo)
  Future<void> cleanupOldSchedules(int daysAgo) async {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: daysAgo));
    final q = await schedules.where('createdAt', isLessThan: Timestamp.fromDate(cutoff)).where('deletedAt', isNull: true).get();
    for (final d in q.docs) {
      await schedules.doc(d.id).update({'deletedAt': Timestamp.now()});
    }
  }
}
