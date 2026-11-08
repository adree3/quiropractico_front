import 'package:flutter/material.dart';

/// Skeleton loader para la vista de agenda que simula una rejilla de calendario
/// con tarjetas de citas con animación Shimmer (ColorTween) sin librerías externas.
class AgendaSkeleton extends StatefulWidget {
  const AgendaSkeleton({super.key});

  @override
  State<AgendaSkeleton> createState() => _AgendaSkeletonState();
}

class _AgendaSkeletonState extends State<AgendaSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        final shimmerColor = _colorAnimation.value ?? Colors.grey.shade200;

        return Container(
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Columna izquierda: Regla horaria simulada
              Container(
                width: 60,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(8, (index) {
                    return Container(
                      width: 32,
                      height: 10,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // Rejilla central con líneas horizontales y 4 tarjetas de citas simuladas
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalHeight = constraints.maxHeight;
                    final totalWidth = constraints.maxWidth;

                    return Stack(
                      children: [
                        // Líneas divisorias horizontales (horas)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(8, (index) {
                            return Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey.shade100,
                            );
                          }),
                        ),

                        // Tarjeta 1 (mañana temprana)
                        Positioned(
                          top: totalHeight * 0.08,
                          left: 16,
                          width: (totalWidth - 32) * 0.45,
                          height: totalHeight * 0.16,
                          child: _buildSkeletonCard(shimmerColor, hasBorderAccent: true),
                        ),

                        // Tarjeta 2 (media mañana)
                        Positioned(
                          top: totalHeight * 0.28,
                          left: totalWidth * 0.25,
                          width: (totalWidth - 32) * 0.55,
                          height: totalHeight * 0.22,
                          child: _buildSkeletonCard(shimmerColor, hasBorderAccent: true),
                        ),

                        // Tarjeta 3 (mediodía)
                        Positioned(
                          top: totalHeight * 0.55,
                          left: 16,
                          width: (totalWidth - 32) * 0.48,
                          height: totalHeight * 0.14,
                          child: _buildSkeletonCard(shimmerColor, hasBorderAccent: true),
                        ),

                        // Tarjeta 4 (tarde)
                        Positioned(
                          top: totalHeight * 0.74,
                          left: totalWidth * 0.35,
                          width: (totalWidth - 32) * 0.52,
                          height: totalHeight * 0.18,
                          child: _buildSkeletonCard(shimmerColor, hasBorderAccent: true),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard(Color shimmerColor, {bool hasBorderAccent = false}) {
    return Container(
      decoration: BoxDecoration(
        color: shimmerColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Row(
        children: [
          if (hasBorderAccent)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 50,
                    height: 8,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

