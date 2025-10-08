import 'package:cloud_firestore/cloud_firestore.dart';

class PresetItem {
  String title;
  String notifyTime;
  String lineMessage;
  String memo;
  bool disabled;

  PresetItem({
    required this.title,
    required this.notifyTime,
    required this.lineMessage,
    required this.memo,
    required this.disabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'notifyTime': notifyTime,
      'lineMessage': lineMessage,
      'memo': memo,
      'disabled': disabled,
    };
  }

  factory PresetItem.fromMap(Map<String, dynamic> m) {
    return PresetItem(
      title: m['title'] ?? '',
      notifyTime: m['notifyTime'] ?? '08:00',
      lineMessage: m['lineMessage'] ?? '',
      memo: m['memo'] ?? '',
      disabled: m['disabled'] ?? false,
    );
  }
}

class Preset {
  String id;
  String name;
  List<PresetItem> items;
  Timestamp createdAt;
  Timestamp? deletedAt;

  Preset({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    this.deletedAt,
  });

  factory Preset.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = (data['items'] as List<dynamic>? ?? []);
    final items = rawItems.map((e) => PresetItem.fromMap(Map<String, dynamic>.from(e))).toList();
    return Preset(
      id: doc.id,
      name: data['name'] ?? '',
      items: items,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      deletedAt: data['deletedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'deletedAt': deletedAt,
    };
  }
}
