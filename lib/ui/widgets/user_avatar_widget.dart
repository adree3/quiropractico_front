import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';

class UserAvatarWidget extends StatelessWidget {
  final Usuario? usuario;
  final int profilePictureVersion;
  final double radius;
  final double fontSize;

  const UserAvatarWidget({
    super.key,
    required this.usuario,
    this.profilePictureVersion = 0,
    this.radius = 20,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (usuario == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: fontSize, color: Colors.grey),
      );
    }

    if (usuario!.tieneFotoPerfil) {
      final photoUrl = '${ApiConfig.baseUrl}/usuarios/${usuario!.idUsuario}/foto-perfil?v=$profilePictureVersion';
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        backgroundImage: NetworkImage(photoUrl, headers: {
          'Authorization': 'Bearer ${LocalStorage.getToken()}'
        }),
      );
    }

    String initials = "U";
    if (usuario!.nombreCompleto.isNotEmpty) {
      initials = usuario!.nombreCompleto.trim().substring(0, 1).toUpperCase();
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      child: Text(
        initials,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
