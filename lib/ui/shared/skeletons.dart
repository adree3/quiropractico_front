import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wrapper base para aplicar el efecto shimmer de forma genérica.
class SkeletonBase extends StatelessWidget {
  final Widget child;

  const SkeletonBase({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}

/// Simula un contenedor estándar gris para skeletons.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SkeletonBase(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Simula un campo de texto (etiqueta + input).
class SkeletonInput extends StatelessWidget {
  final bool showLabel;

  const SkeletonInput({Key? key, this.showLabel = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          SkeletonBox(width: 120, height: 16),
          const SizedBox(height: 8),
        ],
        const SkeletonBox(width: double.infinity, height: 50),
      ],
    );
  }
}

/// Simula una tarjeta grande (como la de Almacenamiento).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonBox(width: 250, height: 20),
              SkeletonBox(width: 40, height: 24),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 12, borderRadius: 10),
          const SizedBox(height: 24),
          Row(
            children: const [
              SkeletonBox(width: 18, height: 18, borderRadius: 9),
              SizedBox(width: 8),
              SkeletonBox(width: 300, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simula un avatar (ej. Logo de la clínica).
class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({Key? key, this.size = 100}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, borderRadius: size / 2);
  }
}
