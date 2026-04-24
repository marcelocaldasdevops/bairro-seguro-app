import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final bool uppercase;

  const SectionTitle({
    super.key,
    required this.title,
    this.uppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      uppercase ? title.toUpperCase() : title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: uppercase ? 1.1 : null,
          ),
    );
  }
}
