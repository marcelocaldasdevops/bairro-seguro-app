import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonIncident extends StatelessWidget {
  const SkeletonIncident({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: 12.0,
                    color: Colors.white,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                  ),
                  Container(
                    width: double.infinity,
                    height: 12.0,
                    color: Colors.white,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                  ),
                  Container(
                    width: 100.0,
                    height: 10.0,
                    color: Colors.white,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
