import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType { success, error, info }

class CustomSnackBar {
  static void show(BuildContext context, {
    required String message,
    String? title,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    Color typeColor;
    IconData icon;
    String defaultTitle;

    switch (type) {
      case SnackBarType.success:
        typeColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle_outline;
        defaultTitle = "Éxito";
        break;
      case SnackBarType.error:
        typeColor = const Color(0xFFE57373);
        icon = Icons.error_outline;
        defaultTitle = "Error";
        break;
      case SnackBarType.info:
        typeColor = const Color(0xFF00AEEF);
        icon = Icons.info_outline;
        defaultTitle = "Información";
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.only(bottom: 30),
        padding: EdgeInsets.zero, 
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _SnackBarContent(
              title: title ?? defaultTitle,
              message: message,
              color: typeColor,
              icon: icon,
              duration: duration,
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para animar la barra de progreso
class _SnackBarContent extends StatefulWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final Duration duration;

  const _SnackBarContent({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.duration,
  });

  @override
  State<_SnackBarContent> createState() => _SnackBarContentState();
}

class _SnackBarContentState extends State<_SnackBarContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward(); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          // CONTENIDO PRINCIPAL
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: widget.color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
                
                const SizedBox(width: 15),

                // Textos
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF333333),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.message,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF757575),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Botón Cerrar
                InkWell(
                  onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, color: Colors.grey, size: 18),
                  ),
                )
              ],
            ),
          ),

          // BARRA DE PROGRESO 
          Positioned(
            bottom: 0,
            left: 4,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _controller.value, 
                  backgroundColor: Colors.transparent,
                  color: widget.color.withOpacity(0.3),
                  minHeight: 3, 
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}