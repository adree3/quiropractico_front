import 'package:flutter/material.dart';
import 'package:quiropractico_front/ui/views/auth/auth_side_panel.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;

  const AuthLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Row(
        children: [
          if (size.width > 900)
            const Expanded(
              flex: 2,
              child: AuthSidePanel(),
            ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[50],
              child: Center(
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
