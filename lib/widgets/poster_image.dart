import 'package:flutter/material.dart';

class PosterImage extends StatelessWidget {
  final String url;
  const PosterImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF1E1E1E),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF323232), Color(0xFF1A1A1A)],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.movie_outlined, color: Color(0xFF8A8A8A), size: 42),
      ),
    );
  }
}