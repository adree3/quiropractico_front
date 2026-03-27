import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class SkeletonFolder extends StatelessWidget {
  const SkeletonFolder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonWidget(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(8))),
          SizedBox(height: 12),
          SkeletonWidget(width: 100, height: 14),
          SizedBox(height: 8),
          SkeletonWidget(width: 60, height: 10),
        ],
      ),
    );
  }
}

class SkeletonDocumentCard extends StatelessWidget {
  final String? label;
  const SkeletonDocumentCard({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                const SkeletonWidget(width: double.infinity, height: double.infinity),
                if (label != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                      child: Text(label!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const SkeletonWidget(width: 80, height: 12),
          const SizedBox(height: 6),
          const SkeletonWidget(width: 40, height: 10),
        ],
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SkeletonWidget(width: 45, height: 45),
      title: const SkeletonWidget(width: 150, height: 14),
      subtitle: const SkeletonWidget(width: 100, height: 10),
      trailing: const SkeletonWidget(width: 40, height: 20),
    );
  }
}
