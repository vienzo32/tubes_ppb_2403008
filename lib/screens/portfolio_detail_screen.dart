import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio_model.dart';
import '../providers/portfolio_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'add_edit_portfolio_screen.dart';
import 'comment_section.dart';
import 'user_profile_screen.dart';

class PortfolioDetailScreen extends ConsumerStatefulWidget {
  final PortfolioModel portfolio;

  const PortfolioDetailScreen({super.key, required this.portfolio});

  @override
  ConsumerState<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends ConsumerState<PortfolioDetailScreen> {
  late int _likeCount;
  late int _commentCount;
  late int _viewsCount;
  bool _isLiking = false;
  bool _isTrackingView = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.portfolio.likes;
    _commentCount = widget.portfolio.commentsCount;
    _viewsCount = widget.portfolio.viewsCount;
    _trackView();
  }

  Future<void> _trackView() async {
    if (_isTrackingView) return;
    
    setState(() {
      _isTrackingView = true;
    });
    
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    final portfolioId = int.parse(widget.portfolio.id);
    
    await ApiService.trackView(portfolioId, userId);
    await ref.read(portfolioListProvider.notifier).loadPortfolios();
    
    if (mounted) {
      final updatedPortfolio = ref.read(portfolioListProvider).value
          ?.firstWhere((p) => p.id == widget.portfolio.id);
      if (updatedPortfolio != null) {
        setState(() {
          _viewsCount = updatedPortfolio.viewsCount;
        });
      }
    }
    
    setState(() {
      _isTrackingView = false;
    });
  }

  Future<void> _handleLike() async {
    final portfolio = widget.portfolio;
    final authState = ref.read(authProvider);
    final currentUserId = authState.userId;
    
    if (currentUserId == portfolio.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa like karya sendiri 😅'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    if (_isLiking) return;
    
    setState(() {
      _isLiking = true;
    });
    
    try {
      final result = await ref.read(portfolioListProvider.notifier)
          .toggleLike(portfolio.id, currentUserId);
      
      if (result['success'] == true) {
        if (result['action'] == 'liked') {
          setState(() {
            _likeCount++;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❤️ Menyukai karya ini!'),
                backgroundColor: AppColors.success,
                duration: Duration(milliseconds: 800),
              ),
            );
          }
        } else {
          setState(() {
            _likeCount--;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('💔 Batal menyukai'),
                backgroundColor: AppColors.textSecondary,
                duration: Duration(milliseconds: 800),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal, coba lagi'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  void _onCommentChanged(int newCommentCount) {
    setState(() {
      _commentCount = newCommentCount;
    });
  }

  void _navigateToUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: widget.portfolio.userId,
          userName: widget.portfolio.userName,
          userRole: widget.portfolio.userRole,
          userEmail: '',
        ),
      ),
    );
  }

  void _showFullscreenImage() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FullscreenImagePage(
        imageUrl: widget.portfolio.imageUrl,
        title: widget.portfolio.title,  // ← KIRIMKAN JUDUL
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final portfolio = widget.portfolio;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final isOwner = authState.userId == portfolio.userId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      portfolio.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar dengan GestureDetector untuk fullscreen
            GestureDetector(
              onTap: _showFullscreenImage,
              child: _buildImage(portfolio),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama User - Bisa diklik untuk lihat profil user tersebut!
                  GestureDetector(
                    onTap: _navigateToUserProfile,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 16, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          portfolio.userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(portfolio.userRole),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRoleDisplay(portfolio.userRole),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Judul & Rank
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          portfolio.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (portfolio.rank != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRankColor(portfolio.rank!),
                                _getRankColor(portfolio.rank!).withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Rank ${portfolio.rank}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.brush, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        portfolio.toolsUsed,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(portfolio.createdAt),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(portfolio.description),
                  const SizedBox(height: 20),
                  const Text(
                    'Gaya Anime',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: portfolio.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.secondary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(color: AppColors.primary),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Stat Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark ? const Color(0xFF1E1E1E) : Colors.grey[50]!,
                          isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Like Button
                        GestureDetector(
                          onTap: _isLiking ? null : _handleLike,
                          child: Column(
                            children: [
                              AnimatedScale(
                                scale: _isLiking ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  Icons.favorite,
                                  size: 32,
                                  color: _likeCount > widget.portfolio.likes 
                                      ? Colors.red 
                                      : (_likeCount > 0 ? Colors.red : Colors.grey[400]),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  '$_likeCount',
                                  key: ValueKey(_likeCount),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Text(
                                'Likes',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Comment Stat
                        Column(
                          children: [
                            Icon(
                              Icons.comment,
                              size: 28,
                              color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                '$_commentCount',
                                key: ValueKey(_commentCount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              'Komentar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        // Views Stat
                        Column(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 28,
                              color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                '$_viewsCount',
                                key: ValueKey(_viewsCount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              'Views',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Comment Section
                  CommentSection(
                    portfolioId: int.parse(portfolio.id),
                    currentUserId: authState.userId,
                    currentUserName: authState.userName,
                    currentUserRole: authState.userRole,
                    onCommentChanged: _onCommentChanged,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Edit & Delete Buttons
                  if (isOwner) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditPortfolioScreen(
                                    portfolio: portfolio,
                                  ),
                                ),
                              );
                              await ref.read(portfolioListProvider.notifier).loadPortfolios();
                              if (mounted) {
                                final updatedPortfolio = ref.read(portfolioListProvider).value
                                    ?.firstWhere((p) => p.id == portfolio.id);
                                if (updatedPortfolio != null) {
                                  setState(() {
                                    _commentCount = updatedPortfolio.commentsCount;
                                    _viewsCount = updatedPortfolio.viewsCount;
                                    _likeCount = updatedPortfolio.likes;
                                  });
                                }
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Portofolio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showDeleteDialog(portfolio.id),
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(PortfolioModel portfolio) {
    if (portfolio.imagePath.isEmpty) {
      return Container(
        height: 350,
        width: double.infinity,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Tidak ada gambar',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Image.network(
      portfolio.imageUrl,
      width: double.infinity,
      height: 350,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 350,
          width: double.infinity,
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Memuat gambar...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Detail image error: $error');
        print('Image URL: ${portfolio.imageUrl}');
        return Container(
          height: 350,
          width: double.infinity,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                'Gambar gagal dimuat',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'URL: ${portfolio.imagePath}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hapus Karya'),
          content: const Text('Apakah Anda yakin ingin menghapus karya ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(portfolioListProvider.notifier).deletePortfolio(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Karya berhasil dihapus')),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'mahasiswa':
        return Colors.blue;
      case 'dosen':
        return Colors.green;
      case 'hrd':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'mahasiswa':
        return 'Mahasiswa';
      case 'dosen':
        return 'Dosen';
      case 'hrd':
        return 'HRD';
      default:
        return 'User';
    }
  }
}

// ============ FULLSCREEN IMAGE PAGE ============
class FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String title;
  const FullscreenImagePage({
    super.key, 
    required this.imageUrl,
    required this.title,  // ← WAJIB DIISI
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,  // ← MENGGUNAKAN JUDUL KARYA
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 80, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Gambar gagal dimuat',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}