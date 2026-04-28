import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';

class AuthSidePanel extends StatelessWidget {
  const AuthSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business_outlined, size: 120, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            'ClinicOS',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Plataforma Integral de Gestión',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}
