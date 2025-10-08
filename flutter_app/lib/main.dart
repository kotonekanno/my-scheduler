import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/home_page.dart';
import 'pages/calendar_page.dart';
import 'pages/presets_page.dart';
import 'pages/settings_page.dart';
import 'services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Note: Replace with your generated firebase_options if you use flutterfire CLI.
// import 'firebase_options.dart';

final firebaseInitProvider = FutureProvider<FirebaseApp>((ref) async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
      );
  // initialize intl for locale formatting
  await initializeDateFormatting();
  return app;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provide FirestoreService once user is signed in (anonymous).
final firestoreServiceProvider = Provider<FirestoreService?>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;
  return FirestoreService(userId: user.uid);
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(firebaseInitProvider);

    return MaterialApp(
      title: 'Simple Scheduler',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: init.when(
        data: (_) => const RootPage(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Firebase init error: $e'))),
      ),
    );
  }
}

class RootPage extends ConsumerStatefulWidget {
  const RootPage({super.key});

  @override
  ConsumerState<RootPage> createState() => _RootPageState();
}

class _RootPageState extends ConsumerState<RootPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // ensure we sign in anonymously if not authenticated
    _ensureAnonymousSignIn();
  }

  Future<void> _ensureAnonymousSignIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = ref.watch(firestoreServiceProvider);

    final pages = <Widget>[
      if (fs != null) HomePage(fs: fs) else const Scaffold(body: Center(child: CircularProgressIndicator())),
      if (fs != null) CalendarPage(fs: fs) else const SizedBox.shrink(),
      if (fs != null) PresetsPage(fs: fs) else const SizedBox.shrink(),
      if (fs != null) SettingsPage(fs: fs) else const SizedBox.shrink(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmarks), label: 'Presets'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
