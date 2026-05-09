import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ModelService {
  final String _baseUrl = dotenv.env['MODEL_API'] ?? '';

  Future<Map<String, dynamic>> analyzeFoodImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final url = '$_baseUrl/analyze/';
      print('Calling API: $url'); // Debug print to verify the URL

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add user ID

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception(
          'Failed to analyze food image: ${response.statusCode} - $responseData',
        );
      }
    } catch (e) {
      throw Exception('Error connecting to food analysis API: $e');
    }
  }

  Future<Map<String, dynamic>> getFoodRecommendations({
    required String userId,
    required List<String> detectedFoods,
  }) async {
    try {
      final url = '$_baseUrl/food-recommendations';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'detected_foods': detectedFoods}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to get food recommendations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting food recommendations: $e');
    }
  }
}
