import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/auth_state.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/list.dart';
import 'widgets/app_navbar.dart';

void main() {
  //  AuthState provider
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
    );
  }
}

// Main Navigation
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    LandingPage(),
    MedicineListPage(),
    LoginPage(),
    SignupPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppNavbar(),
      ),

      // Page content
      body: pages[index],

      // Bottom navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.login), label: 'Sign in'),
        ],
      ),
    );
  }
}
