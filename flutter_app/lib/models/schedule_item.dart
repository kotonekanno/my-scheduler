// English comments and UI strings
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleItem {
  String id;
  String title;
  String date; // YYYY-MM-DD
  String notifyTime; // HH:mm
  DateTime notifyAtUtc;
  String lineMessage;
  String memo;
  bool disabled;
  String? presetSourceId;
  Timestamp createdAt;
  Timestamp? deletedAt;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.date,
    required this.notifyTime,
    required this.notifyAtUtc,
    required this.lineMessage,
    required this.memo,
    required this.disabled,
    this.presetSourceId,
    required this.createdAt,
    this.deletedAt,
  });

  factory ScheduleItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleItem(
      id: doc.id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      notifyTime: data['notifyTime'] ?? '',
      notifyAtUtc: (data['notifyAtUtc'] as Timestamp).toDate().toUtc(),
      lineMessage: data['lineMessage'] ?? '',
      memo: data['memo'] ?? '',
      disabled: data['disabled'] ?? false,
      presetSourceId: data['presetSourceId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      deletedAt: data['deletedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'notifyTime': notifyTime,
      'notifyAtUtc': Timestamp.fromDate(notifyAtUtc.toUtc()),
      'lineMessage': lineMessage,
      'memo': memo,
      'disabled': disabled,
      'presetSourceId': presetSourceId,
      'createdAt': createdAt,
      'deletedAt': deletedAt,
    };
  }
}
