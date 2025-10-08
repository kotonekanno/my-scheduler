import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  final FirestoreService fs;
  const SettingsPage({required this.fs, super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _tokenCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.fs.userId)
        .collection('meta')
        .doc('settings')
        .get();
    if (doc.exists) {
      final data = doc.data();
      _tokenCtrl.text = data?['lineNotifyToken'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.fs.userId)
        .collection('meta')
        .doc('settings')
        .set({'lineNotifyToken': _tokenCtrl.text.trim()});
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text('LINE Notify token (personal token). Keep it secret.'),
                  TextField(
                    controller: _tokenCtrl,
                    decoration: const InputDecoration(labelText: 'LINE Notify token'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                  const SizedBox(height: 12),
                  const Text('Note: token will be stored in Firestore under users/{uid}/meta/settings'),
                ],
              ),
            ),
    );
  }
}
