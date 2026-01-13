import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'state/auth_state.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/list.dart';
import 'pages/donate_page.dart';
import 'pages/request_page.dart';
import 'pages/admin_panel.dart';
import 'pages/user_panel.dart';
import 'widgets/app_navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await supabase.Supabase.initialize(
    url: 'https://tmgcwukjqxtwnmnqrdne.supabase.co',
    anonKey: 'sb_publishable_xTXkUULZ7qLm5ZNpQPvlXw_mGLh9zqO',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthState(),
      child: const MediShareApp(),
    ),
  );
}

// Main App
class MediShareApp extends StatelessWidget {
  const MediShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediShare',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MainShell(),
      routes: {
        '/home': (_) => const MainShell(),
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignupPage(),
        '/donate': (_) => const DonatePage(),
        '/request': (_) => const RequestPage(),
        '/browse': (_) => const MedicineListPage(),
        '/admin': (_) => const AdminPanel(),
        '/profile': (_) => const UserPanel(),
      },
    );
  }
}

// Main Navigation Shell
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const LandingPage(),
      const MedicineListPage(),
      const DonatePage(),
      const RequestPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppNavbar(),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.list), label: 'Browse'),
          NavigationDestination(
            icon: auth.isLoggedIn
                ? const Icon(Icons.favorite)
                : const Icon(Icons.favorite_outline),
            label: 'Donate',
          ),
        ],
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin'),
              backgroundColor: Colors.red,
            )
          : null,
    );
  }
}
