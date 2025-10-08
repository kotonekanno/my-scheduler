import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/schedule_item.dart';
import 'home_page.dart';

class CalendarPage extends StatefulWidget {
  final FirestoreService fs;
  const CalendarPage({required this.fs, super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  // multiple selection for bulk preset apply
  Set<DateTime> _multiSelected = {};

  Future<List<ScheduleItem>> _schedulesFor(DateTime day) {
    final date = DateFormat('yyyy-MM-dd').format(day);
    return widget.fs.getSchedulesForDate(date);
  }

  // Toggle date in multi-selection
  void _toggleMultiSelect(DateTime d) {
    setState(() {
      final normalized = DateTime(d.year, d.month, d.day);
      if (_multiSelected.any((e) => isSameDay(e, normalized))) {
        _multiSelected.removeWhere((e) => isSameDay(e, normalized));
      } else {
        _multiSelected.add(normalized);
      }
    });
  }

  // Quick action to apply preset to selected dates (opens preset selection)
  Future<void> _applyPresetToSelected() async {
    if (_multiSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No dates selected')));
      return;
    }
    // Open preset pick (simple dialog)
    final presets = await widget.fs.listPresets();
    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No presets available')));
      return;
    }
    final chosen = await showDialog<String?>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pick preset to apply'),
        children: presets.map((p) => SimpleDialogOption(
          child: Text(p.name),
          onPressed: () => Navigator.pop(context, p.id),
        )).toList(),
      ),
    );
    if (chosen == null) return;
    // apply to each selected date
    for (final d in _multiSelected) {
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      await widget.fs.applyPresetToDate(chosen, dateStr);
    }
    setState(() {
      _multiSelected.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset applied to selected dates')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: _applyPresetToSelected,
            tooltip: 'Apply preset to selected dates',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focused,
            calendarFormat: _format,
            selectedDayPredicate: (d) => _multiSelected.any((e) => isSameDay(e, d)),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selected = selectedDay;
                _focused = focusedDay;
              });
              // Toggle multi-select on tap with Ctrl/long press semantics approximated:
              _toggleMultiSelect(selectedDay);
            },
            onFormatChanged: (fmt) {
              setState(() => _format = fmt);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // optional: show dot if schedules exist
                return FutureBuilder<List<ScheduleItem>>(
                  future: _schedulesFor(date),
                  builder: (c, s) {
                    if (!s.hasData) return const SizedBox.shrink();
                    if (s.data!.isEmpty) return const SizedBox.shrink();
                    return const Align(alignment: Alignment.bottomCenter, child: CircleAvatar(radius: 4));
                  },
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _selected == null
                ? const Center(child: Text('Select a date to see schedules'))
                : FutureBuilder<List<ScheduleItem>>(
                    future: _schedulesFor(_selected!),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                      final list = snap.data ?? [];
                      if (list.isEmpty) return const Center(child: Text('No schedules for selected date'));
                      return ListView(
                        children: list.map((it) => ListTile(
                          title: Text(it.title),
                          subtitle: Text('${it.notifyTime} • ${it.memo}'),
                          trailing: TextButton(
                            child: const Text('Edit'),
                            onPressed: () {
                              // navigate to Home page and set focused date
                              // for simplicity just show snackbar
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Press Home to edit this date')));
                            },
                          ),
                        )).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
