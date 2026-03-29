import 'package:flutter/material.dart';

class MovieDetailsPage extends StatelessWidget {
  const MovieDetailsPage({super.key, required this.movie});

  final MovieDetails movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    movie.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1E1E1E),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: Color(0xFF8A8A8A),
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                movie.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: movie.category),
                  _InfoChip(label: '${movie.year}'),
                  _InfoChip(label: movie.duration),
                  _InfoChip(label: '★ ${movie.rating.toStringAsFixed(1)}'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Описание',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                movie.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: Color(0xFFCBCBCB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFB8B8B8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class MovieDetails {
  const MovieDetails({
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.year,
    required this.duration,
    required this.rating,
    required this.description,
  });

  final String title;
  final String imageUrl;
  final String category;
  final int year;
  final String duration;
  final double rating;
  final String description;
}
