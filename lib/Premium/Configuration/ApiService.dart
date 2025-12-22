// lib/configuration/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'ApiUrlConfig.dart';

class ApiService {
  final ApiUrlConfig apiUrlConfig; // Inject ApiUrlConfig

  ApiService({required this.apiUrlConfig});

  Future<Map<String, dynamic>> makeRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final String baseUrl = apiUrlConfig.baseUrl;
    final requestUrl = Uri.parse('$baseUrl$endpoint');
    final Map<String, String> defaultHeaders = {
      'Content-Type': 'application/json',
    };

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(
            requestUrl,
            headers: headers ?? defaultHeaders,
          );
          break;
        case 'POST':
          response = await http.post(
            requestUrl,
            headers: headers ?? defaultHeaders,
            body: json.encode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            requestUrl,
            headers: headers ?? defaultHeaders,
            body: json.encode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(
            requestUrl,
            headers: headers ?? defaultHeaders,
            body: json.encode(body),
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is List) {
          return {'success': true, 'data': decodedResponse};
        } else if (decodedResponse is Map) {
          return {'success': true, 'data': decodedResponse};
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        return {
          'success': false,
          'message': 'Error: ${response.statusCode} - ${response.body}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Network error: Unable to reach the server.'
      };
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> makeMultipartRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    required Map<String, String> formData,
    Map<String, File>? files, // Changed to support multiple files
    List<String>?
        fileFieldNames, // Added to specify field names for multiple files
  }) async {
    final String baseUrl = apiUrlConfig.baseUrl;
    final requestUrl = Uri.parse('$baseUrl$endpoint');
    final Map<String, String> defaultHeaders = {
      'Authorization': 'Bearer default_token_here', // Adjust as needed
    };

    try {
      var request = http.MultipartRequest(method.toUpperCase(), requestUrl);
      request.headers.addAll({
        ...defaultHeaders,
        ...?headers,
      });

      // Add form data
      formData.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add multiple files if provided
      if (files != null &&
          fileFieldNames != null &&
          files.isNotEmpty &&
          fileFieldNames.isNotEmpty) {
        if (files.length != fileFieldNames.length) {
          throw Exception('Number of files and file field names must match');
        }
        for (int i = 0; i < fileFieldNames.length; i++) {
          final file = files[fileFieldNames[i]];
          if (file != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                fileFieldNames[i],
                file.path,
                filename: file.path.split('/').last,
              ),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is List) {
          return {'success': true, 'data': decodedResponse};
        } else if (decodedResponse is Map) {
          return {'success': true, 'data': decodedResponse};
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        return {
          'success': false,
          'message': 'Error: ${response.statusCode} - ${response.body}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Network error: Unable to reach the server.'
      };
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadImageRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    required Map<String, String> formData,
    Map<String, File>? files, // Changed to support multiple files
    List<String>?
        fileFieldNames, // Added to specify field names for multiple files
  }) async {
    final String baseUrl = apiUrlConfig.baseUrl;
    final requestUrl = Uri.parse(endpoint);
    final Map<String, String> defaultHeaders = {
      'Authorization': 'Bearer default_token_here', // Adjust as needed
    };

    try {
      var request = http.MultipartRequest(method.toUpperCase(), requestUrl);
      request.headers.addAll({
        ...defaultHeaders,
        ...?headers,
      });

      // Add form data
      formData.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add multiple files if provided
      if (files != null &&
          fileFieldNames != null &&
          files.isNotEmpty &&
          fileFieldNames.isNotEmpty) {
        if (files.length != fileFieldNames.length) {
          throw Exception('Number of files and file field names must match');
        }
        for (int i = 0; i < fileFieldNames.length; i++) {
          final file = files[fileFieldNames[i]];
          if (file != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                fileFieldNames[i],
                file.path,
                filename: file.path.split('/').last,
              ),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is List) {
          return {'success': true, 'data': decodedResponse};
        } else if (decodedResponse is Map) {
          return {'success': true, 'data': decodedResponse};
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        return {
          'success': false,
          'message': 'Error: ${response.statusCode} - ${response.body}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Network error: Unable to reach the server.'
      };
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }
}
