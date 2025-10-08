import 'package:flutter/material.dart';
import '../models/schedule_item.dart';

class ScheduleTile extends StatelessWidget {
  final ScheduleItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleDisable;

  const ScheduleTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDisable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = item.disabled
        ? TextStyle(color: Colors.grey)
        : TextStyle(color: Colors.black, fontWeight: FontWeight.bold);

    return Card(
      child: ListTile(
        leading: Text(item.notifyTime, style: textStyle),
        title: Text(item.title, style: textStyle),
        subtitle: Text(item.memo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.notifications_off), onPressed: onToggleDisable),
            IconButton(icon: Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
