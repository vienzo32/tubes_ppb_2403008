import 'package:flutter/material.dart';
import '../models/portfolio_model.dart';
import '../utils/app_colors.dart';

class ProfilePortfolioCard extends StatelessWidget {
  final PortfolioModel portfolio;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isOwner;

  const ProfilePortfolioCard({
    super.key,
    required this.portfolio,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildImage(),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Judul + Rank
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          portfolio.title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (portfolio.rank != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getRankColor(portfolio.rank!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            portfolio.rank!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Deskripsi
                  Text(
                    portfolio.description,
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tags
                  Wrap(
                    spacing: 3,
                    runSpacing: 1,
                    children: portfolio.tags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 7,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 5),
                  // Like & Action Buttons
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 11,
                        color: portfolio.likes > 0 ? AppColors.primary : Colors.grey[400],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${portfolio.likes}',
                        style: const TextStyle(fontSize: 9),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.comment,
                        size: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${portfolio.commentsCount}',
                        style: const TextStyle(fontSize: 9),
                      ),
                      const Spacer(),
                      if (isOwner && onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 13),
                          onPressed: onEdit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppColors.primary,
                        ),
                      if (isOwner && onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 13, color: Colors.red),
                          onPressed: onDelete,
                          padding: const EdgeInsets.only(left: 4),
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (portfolio.imagePath.isEmpty) {
      return Container(
        height: 110,
        width: double.infinity,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 25, color: Colors.grey[600]),
            const SizedBox(height: 2),
            Text(
              'No Image',
              style: TextStyle(fontSize: 8, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Image.network(
      portfolio.imageUrl, // ← menggunakan imageUrl
      height: 110,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 110,
          width: double.infinity,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Profile image error: $error');
        return Container(
          height: 110,
          width: double.infinity,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 25, color: Colors.grey[600]),
              const SizedBox(height: 2),
              Text(
                'Gambar gagal dimuat',
                style: TextStyle(fontSize: 8, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'S':
        return Colors.amber;
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}