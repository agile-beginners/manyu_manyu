import 'dart:io';
import 'package:http/http.dart' as http;

/// Network connectivity checker
class NetworkInfo {
  /// Checks if device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      print('🔍 Checking internet connection...');
      
      // Try to connect to Google's DNS
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Internet connection available (DNS lookup successful)');
        return true;
      } else {
        print('❌ No internet connection (DNS lookup failed)');
        return false;
      }
    } catch (e) {
      print('❌ Internet connection check failed: $e');
      return false;
    }
  }
  
  /// Tests HTTP connectivity to a specific URL
  static Future<bool> canReachUrl(String url) async {
    try {
      print('🔍 Testing connectivity to: $url');
      
      final response = await http.head(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      
      final canReach = response.statusCode >= 200 && response.statusCode < 400;
      print(canReach 
          ? '✅ Can reach $url (Status: ${response.statusCode})'
          : '❌ Cannot reach $url (Status: ${response.statusCode})');
      
      return canReach;
    } on SocketException catch (e) {
      print('❌ SocketException for $url:');
      print('  Message: ${e.message}');
      print('  OS Error: ${e.osError}');
      print('  Address: ${e.address}');
      print('  Port: ${e.port}');
      return false;
    } catch (e) {
      print('❌ Failed to reach $url: $e');
      print('  Error type: ${e.runtimeType}');
      return false;
    }
  }
  
  /// Comprehensive network diagnostics
  static Future<Map<String, dynamic>> runNetworkDiagnostics() async {
    print('🔬 Running network diagnostics...');
    
    final diagnostics = <String, dynamic>{};
    
    // Basic internet connectivity
    diagnostics['hasInternet'] = await hasInternetConnection();
    
    // Test Google connectivity
    diagnostics['canReachGoogle'] = await canReachUrl('https://google.com');
    
    // Test Gemini API base URL
    diagnostics['canReachGeminiApi'] = await canReachUrl('https://generativelanguage.googleapis.com');
    
    // Test specific Gemini API endpoint
    diagnostics['canReachGeminiEndpoint'] = await canReachUrl('https://generativelanguage.googleapis.com/v1beta/models');
    
    // Test alternative endpoints
    diagnostics['canReachGeminiV1'] = await canReachUrl('https://generativelanguage.googleapis.com/v1/models');
    
    // DNS resolution test
    try {
      final dnsResult = await InternetAddress.lookup('generativelanguage.googleapis.com')
          .timeout(const Duration(seconds: 5));
      diagnostics['geminiApiDnsResolved'] = dnsResult.isNotEmpty;
      diagnostics['geminiApiIpAddresses'] = dnsResult.map((addr) => addr.address).toList();
    } catch (e) {
      diagnostics['geminiApiDnsResolved'] = false;
      diagnostics['geminiApiDnsError'] = e.toString();
    }
    
    print('📊 Network diagnostics complete:');
    diagnostics.forEach((key, value) {
      print('  $key: $value');
    });
    
    return diagnostics;
  }
}