import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/preset.dart';

class PresetsPage extends StatefulWidget {
  final FirestoreService fs;
  const PresetsPage({required this.fs, super.key});

  @override
  State<PresetsPage> createState() => _PresetsPageState();
}

class _PresetsPageState extends State<PresetsPage> {
  Future<List<Preset>> _load() => widget.fs.listPresets();

  Future<void> _createPresetDialog() async {
    final nameCtrl = TextEditingController();
    final items = <PresetItem>[];

    // simple flow: create name then add one item; user can add items after created
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Preset'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Preset name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (created ?? false) {
      await widget.fs.createPreset(nameCtrl.text.trim(), items);
      setState(() {});
    }
  }

  Future<void> _openPresetEditor(Preset p) async {
    // For brevity: simple view, not full editor.
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Preset: ${p.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: p.items.map((it) => ListTile(
            title: Text(it.title),
            subtitle: Text('${it.notifyTime} • ${it.lineMessage}'),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(onPressed: () async {
            // soft delete
            await widget.fs.softDeletePreset(p.id);
            Navigator.pop(context);
            setState(() {});
          }, child: const Text('Delete Preset')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presets'),
      ),
      body: FutureBuilder<List<Preset>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final presets = snap.data ?? [];
          if (presets.isEmpty) return const Center(child: Text('No presets defined'));
          return ListView(
            children: presets.map((p) => ListTile(
              title: Text(p.name),
              subtitle: Text('${p.items.length} items'),
              onTap: () => _openPresetEditor(p),
            )).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPresetDialog,
        child: const Icon(Icons.add),
        tooltip: 'Create Preset',
      ),
    );
  }
}
