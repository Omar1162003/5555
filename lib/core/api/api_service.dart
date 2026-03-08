import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user.dart';
import '../../models/book.dart';

class ApiService {
  static const String baseUrl = 'https://petrifiable-overcanny-caterina.ngrok-free.dev/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

  static Future<User> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/User/register');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "Name": name,
          "Email": email.trim(),
          "password": password,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) return User.fromJson(responseData);
      else if (response.statusCode == 400) throw ApiException(responseData['message'] ?? 'البيانات المرسلة غير صحيحة');
      else throw ApiException(responseData['message'] ?? 'فشل التسجيل');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('تأكد من تشغيل السيرفر ووصلة الـ ngrok');
    }
  }

  static Future<User> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/User/login');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(data['message'] ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('تأكد من تشغيل السيرفر ووصلة الـ ngrok');
    }
  }

  static Future<List<Book>> getBooks() async {
    final url = Uri.parse('$baseUrl/Books');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw ApiException('فشل في جلب الكتب');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('تأكد من تشغيل السيرفر ووصلة الـ ngrok');
    }
  }

  static Future<List<Book>> searchBooks(String query) async {
    // If there is no dedicated search endpoint, we fetch all books and filter locally
    // For now we assume fetch all + local filter since there's no search endpoint in original file
    try {
      final books = await getBooks();
      return books.where((b) => 
        b.title.toLowerCase().contains(query.toLowerCase()) || 
        b.author.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> checkoutBook(String userId, String bookId) async {
    final url = Uri.parse('$baseUrl/Books/checkout');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'bookId': bookId,
        }),
      );
      if (response.statusCode != 200) {
        throw ApiException('فشل استعارة الكتاب');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('حدث خطأ أثناء الاتصال بالخادم');
    }
  }

  static Future<void> returnBook(String userId, String bookId) async {
    final url = Uri.parse('$baseUrl/Books/return');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'bookId': bookId,
        }),
      );
      if (response.statusCode != 200) {
        throw ApiException('فشل إرجاع الكتاب');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('حدث خطأ أثناء الاتصال بالخادم');
    }
  }

  static Future<bool> updateUserStatus(String userId) async {
    final url = Uri.parse('$baseUrl/User/update-status/$userId');
    try {
      final response = await http.put(url, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}