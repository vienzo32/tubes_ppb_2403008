import '../services/api_service.dart';

class PortfolioModel {
  final String id;
  final int userId;
  final String userName;
  final String userRole;
  final String title;
  final String description;
  final String imagePath;
  final String? speedDrawingPath;
  final List<String> tags;
  final String toolsUsed;
  final DateTime createdAt;
  final int likes;
  final int commentsCount;
  final int viewsCount;
  final String? rank;

  PortfolioModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.title,
    required this.description,
    required this.imagePath,
    this.speedDrawingPath,
    required this.tags,
    required this.toolsUsed,
    required this.createdAt,
    this.likes = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.rank,
  });

  // Getter untuk mendapatkan full URL gambar
  String get imageUrl {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return ApiService.getImageUrl(imagePath);
  }

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      id: json['id'].toString(),
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Unknown',
      userRole: json['user_role'] ?? 'mahasiswa',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['image_path'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      toolsUsed: json['tools_used'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      likes: json['likes'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      rank: json['tier_rank'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'toolsUsed': toolsUsed,
      'rank': rank,
      'tags': tags,
    };
  }

  PortfolioModel copyWith({
    String? id,
    int? userId,
    String? userName,
    String? userRole,
    String? title,
    String? description,
    String? imagePath,
    String? speedDrawingPath,
    List<String>? tags,
    String? toolsUsed,
    DateTime? createdAt,
    int? likes,
    int? commentsCount,
    int? viewsCount,
    String? rank,
  }) {
    return PortfolioModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      speedDrawingPath: speedDrawingPath ?? this.speedDrawingPath,
      tags: tags ?? this.tags,
      toolsUsed: toolsUsed ?? this.toolsUsed,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      rank: rank ?? this.rank,
    );
  }
}