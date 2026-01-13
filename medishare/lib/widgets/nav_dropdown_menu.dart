import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';

class NavDropdownMenu extends StatelessWidget {
  const NavDropdownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      elevation: 8,
      color: Colors.white,
      offset: const Offset(0, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleSelection(context, value, auth),
      itemBuilder: (_) => [
        _menuItem('profile', Icons.person, 'Profile'),
        _menuItem('browse', Icons.local_pharmacy, 'Browse Medicines'),
        _menuItem('donate', Icons.add_circle_outline, 'Donate Medicine'),
        _menuItem('request', Icons.shopping_bag_outlined, 'Request Medicine'),
        _menuItem('mydonations', Icons.card_giftcard, 'My Donations'),
        _menuItem('received', Icons.inbox, 'Received'),
        const PopupMenuDivider(),
        _menuItem('logout', Icons.logout, 'Logout', color: Colors.red),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 4, 113, 78),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.menu, color: Colors.white),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String text, {
    Color color = Colors.black,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  void _handleSelection(BuildContext context, String value, AuthState auth) {
    switch (value) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'browse':
        Navigator.pushNamed(context, '/browse');
        break;
      case 'donate':
        Navigator.pushNamed(context, '/donate');
        break;
      case 'request':
        Navigator.pushNamed(context, '/request');
        break;
      case 'logout':
        auth.logout();
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
    }
  }
}
