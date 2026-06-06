import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/portfolio_model.dart';

class ApiService {
  // Ganti dengan IP komputer Anda jika pakai HP fisik
  // Untuk emulator Android: 10.0.2.2
  // Untuk HP fisik: cari IP dengan 'ipconfig' di CMD
  static const String baseUrl = 'http://10.0.160.96/animeport_api';
  // static const String baseUrl = 'http://192.168.1.100/animeport_api'; // Ganti dengan IP Anda
  
  // Fungsi untuk mendapatkan full URL gambar dari relative path
  static String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    // Jika sudah full URL, return as-is
    if (imagePath.startsWith('http')) return imagePath;
    // Jika relative path, tambahkan baseUrl
    return '$baseUrl/$imagePath';
  }

  // ============ REGISTER ============
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
      }),
    );
    return jsonDecode(response.body);
  }

  // ============ LOGIN ============
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // ============ UPLOAD GAMBAR ============
  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_image.php'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('Upload response: $responseBody');
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        return {'success': false, 'message': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('Upload error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============ GET ALL PORTFOLIOS ============
  static Future<List<PortfolioModel>> getPortfolios() async {
    final response = await http.get(Uri.parse('$baseUrl/get_portfolios.php'));
    final data = jsonDecode(response.body);
    
    if (data['success'] == true) {
      List<dynamic> list = data['data'];
      return list.map((json) => PortfolioModel.fromJson(json)).toList();
    }
    return [];
  }

  // ============ CREATE PORTFOLIO ============
  static Future<bool> createPortfolio(PortfolioModel portfolio, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_portfolio.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          ...portfolio.toJson(),
        }),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Create portfolio error: $e');
      return false;
    }
  }

  // ============ UPDATE PORTFOLIO ============
  static Future<bool> editPortfolio(PortfolioModel portfolio) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_portfolio.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': int.parse(portfolio.id),
          ...portfolio.toJson(),
        }),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Edit portfolio error: $e');
      return false;
    }
  }

  // ============ DELETE PORTFOLIO ============
  static Future<bool> deletePortfolio(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_portfolio.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': int.parse(id)}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Delete portfolio error: $e');
      return false;
    }
  }

  // ============ TOGGLE LIKE ============
  static Future<Map<String, dynamic>> toggleLike(String id, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/toggle_like.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': int.parse(id), 'user_id': userId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Toggle like error: $e');
      return {'success': false, 'action': 'error', 'message': e.toString()};
    }
  }

  // ============ GET COMMENTS ============
  static Future<List<Map<String, dynamic>>> getComments(int portfolioId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_comments.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'portfolio_id': portfolioId}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        return [];
      }
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      print('Error getComments: $e');
      return [];
    }
  }

  // ============ ADD COMMENT ============
  static Future<Map<String, dynamic>> addComment({
    required int portfolioId,
    required int userId,
    required String userName,
    required String userRole,
    required String content,
  }) async {
    try {
      final body = jsonEncode({
        'portfolio_id': portfolioId,
        'user_id': userId,
        'user_name': userName,
        'user_role': userRole,
        'content': content,
      });
      
      final response = await http.post(
        Uri.parse('$baseUrl/add_comment.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        return {'success': false, 'message': 'HTTP Error: ${response.statusCode}'};
      }
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Add comment error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============ DELETE COMMENT ============
  static Future<bool> deleteComment(int commentId, int portfolioId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_comment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'comment_id': commentId,
          'portfolio_id': portfolioId,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Delete comment error: $e');
      return false;
    }
  }

  // ============ TRACK VIEW ============
  static Future<bool> trackView(int portfolioId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/track_view.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'portfolio_id': portfolioId,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 5));
      
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Track view error: $e');
      return false;
    }
  }

// ============ REGISTER (untuk Google Sign-In) ============
  static Future<Map<String, dynamic>> registerWithGoogle({
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register_google.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'role': role,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}