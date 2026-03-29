import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'poster_image.dart';

class MovieCard extends StatelessWidget {
  final MovieItem movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PosterImage(url: movie.imageUrl),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            movie.category,
            style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
          ),
        ],
      ),
    );
  }
}