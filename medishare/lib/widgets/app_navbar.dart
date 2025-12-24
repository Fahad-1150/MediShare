import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';

class AppNavbar extends StatelessWidget {
  const AppNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: Row(
        children: [
          
          
          const SizedBox(width: 10),

          
          const Text(
            'MediShare',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ],
      ),
      actions: [
        if (auth.isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: auth.logout,
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          const SizedBox(width: 12),
      ],
    );
  }
}
