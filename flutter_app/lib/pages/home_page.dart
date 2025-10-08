import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/schedule_item.dart';
import '../widgets/schedule_tile.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class HomePage extends ConsumerStatefulWidget {
  final FirestoreService fs;
  const HomePage({required this.fs, super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  DateTime current = DateTime.now();

  Future<List<ScheduleItem>> _load() async {
    final date = DateFormat('yyyy-MM-dd').format(current);
    return widget.fs.getSchedulesForDate(date);
  }

  void _prevDay() {
    setState(() {
      current = current.subtract(Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      current = current.add(Duration(days: 1));
    });
  }

  void _gotoDate(DateTime d) {
    setState(() {
      current = d;
    });
  }

  // simple dialog to add quick schedule (minimal)
  Future<void> _addQuickSchedule() async {
    final date = DateFormat('yyyy-MM-dd').format(current);
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '09:00');
    final lineCtrl = TextEditingController();
    final memoCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Create schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: timeCtrl, decoration: InputDecoration(labelText: 'Time (HH:mm)')),
            TextField(controller: lineCtrl, decoration: InputDecoration(labelText: 'LINE message')),
            TextField(controller: memoCtrl, decoration: InputDecoration(labelText: 'Memo (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () async {
            final title = titleCtrl.text.trim();
            if (title.isEmpty) return;
            final notifyAt = DateTime.parse('${date}T${timeCtrl.text}:00').toUtc();
            final item = ScheduleItem(
              id: '',
              title: title,
              date: date,
              notifyTime: timeCtrl.text,
              notifyAtUtc: notifyAt,
              lineMessage: lineCtrl.text,
              memo: memoCtrl.text,
              disabled: false,
              presetSourceId: null,
              createdAt: Timestamp.now(),
              deletedAt: null,
            );
            await widget.fs.addOrUpdateSchedule(item);
            Navigator.pop(context);
            setState(() {});
          }, child: Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('EEE, yyyy-MM-dd').format(current);
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: _prevDay, icon: Icon(Icons.arrow_back)),
              TextButton(onPressed: () {
                _gotoDate(DateTime.now());
              }, child: Text('Today')),
              IconButton(onPressed: _nextDay, icon: Icon(Icons.arrow_forward)),
              SizedBox(width: 12),
              Text(dateString),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<ScheduleItem>>(
              future: _load(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return Center(child: CircularProgressIndicator());
                final items = snap.data ?? [];
                if (items.isEmpty) return Center(child: Text('No schedules for this date.'));
                return ListView(
                  children: items.map((it) => ScheduleTile(
                    item: it,
                    onEdit: () {
                      // For brevity, reuse quick edit dialog (not full edit screen)
                    },
                    onDelete: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Delete'),
                          content: Text('Delete this schedule?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('OK')),
                          ],
                        ),
                      );
                      if (ok ?? false) {
                        await widget.fs.deleteScheduleSoft(it.id);
                        setState(() {});
                      }
                    },
                    onToggleDisable: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(it.disabled ? 'Enable notification' : 'Disable notification'),
                          content: Text('Are you sure?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('OK')),
                          ],
                        ),
                      );
                      if (confirm ?? false) {
                        await widget.fs.toggleDisable(it.id, !it.disabled);
                        setState(() {});
                      }
                    },
                  )).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuickSchedule,
        child: Icon(Icons.add),
      ),
    );
  }
}
