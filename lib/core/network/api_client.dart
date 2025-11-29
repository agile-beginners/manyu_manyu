import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// HTTP client wrapper for API calls
class ApiClient {
  final http.Client _client;
  
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  
  /// GET request
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: _buildHeaders(headers),
          )
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));
      
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('HTTP error occurred');
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }
  
  /// POST request
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));
      
      print('📥 HTTP ${response.statusCode} - Body: ${response.body.length} chars');
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      print('🔌 SocketException: ${e.message}');
      throw NetworkException('No internet connection: ${e.message}');
    } on HttpException catch (e) {
      print('🌐 HttpException: $e');
      throw NetworkException('HTTP error occurred: ${e.message}');
    } catch (e) {
      print('❌ Network error: $e');
      throw NetworkException('Network error: $e');
    }
  }
  
  /// PUT request
  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));
      
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('HTTP error occurred');
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }
  
  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse(url),
            headers: _buildHeaders(headers),
          )
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));
      
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('HTTP error occurred');
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }
  
  /// Multipart request for file uploads
  Future<Map<String, dynamic>> multipartRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    try {
      final request = http.MultipartRequest(method, Uri.parse(url));
      
      if (headers != null) {
        request.headers.addAll(_buildHeaders(headers));
      }
      
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      if (files != null) {
        request.files.addAll(files);
      }
      
      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));
      
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('HTTP error occurred');
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }
  
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    
    return headers;
  }
  
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException('Failed to parse response: $e');
      }
    } else {
      String errorMessage = 'HTTP ${response.statusCode}';
      
      print('🚨 Error ${response.statusCode}: ${response.body}');
      
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = errorBody['message'] ?? errorMessage;
        
        if (errorBody.containsKey('error')) {
          final error = errorBody['error'];
          if (error is Map && error.containsKey('message')) {
            errorMessage = error['message'];
          }
        }
      } catch (_) {
        // Use default error message if parsing fails
      }
      
      throw ApiException(
        errorMessage,
        code: response.statusCode.toString(),
      );
    }
  }
  
  void dispose() {
    _client.close();
  }
}