import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AwsS3Service {
  static final AwsS3Service _instance = AwsS3Service._internal();
  factory AwsS3Service() => _instance;
  AwsS3Service._internal();

  // These should be loaded from environment variables or config
  // For now, using placeholder values - should be configured in .env
  String get bucketName => 'your-bucket-name'; // Load from config
  String get region => 'us-east-1'; // Load from config
  String get accessKeyId => 'your-access-key'; // Load from config
  String get secretAccessKey => 'your-secret-key'; // Load from config

  // Upload image to S3 via backend API
  // The backend handles the actual S3 upload
  Future<String> uploadImage(File imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      print('📤 [AwsS3Service] Starting image upload: ${imageFile.path}');

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;

      print('📤 [AwsS3Service] File size: ${bytes.length} bytes, Filename: $fileName');

      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // Default
      final extension = fileName.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      print('📤 [AwsS3Service] Content type: $contentType');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/services/upload-image'),
      );

      // Set authorization header - DO NOT set Content-Type for multipart
      request.headers['Authorization'] = 'Bearer $token';
      
      // Ensure filename has correct extension for backend detection
      String finalFileName = fileName;
      if (!finalFileName.toLowerCase().endsWith('.jpg') && 
          !finalFileName.toLowerCase().endsWith('.jpeg') &&
          !finalFileName.toLowerCase().endsWith('.png') &&
          !finalFileName.toLowerCase().endsWith('.gif') &&
          !finalFileName.toLowerCase().endsWith('.webp')) {
        // Add extension based on content type
        switch (contentType) {
          case 'image/png':
            finalFileName = '$fileName.png';
            break;
          case 'image/gif':
            finalFileName = '$fileName.gif';
            break;
          case 'image/webp':
            finalFileName = '$fileName.webp';
            break;
          default:
            finalFileName = '$fileName.jpg';
        }
      }
      
      // Create multipart file with proper field name
      // The field name must match what the backend expects: 'image'
      final multipartFile = http.MultipartFile(
        'image',
        Stream.value(bytes),
        bytes.length,
        filename: finalFileName,
      );
      
      request.files.add(multipartFile);

      print('📤 [AwsS3Service] Sending request to: ${ApiConfig.baseUrl}/services/upload-image');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 [AwsS3Service] Response status: ${response.statusCode}');
      print('📥 [AwsS3Service] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 [AwsS3Service] Parsed data: $data');
        
        // Check for url in different possible locations and nested structures
        String? imageUrl;
        
        // Try top-level first
        imageUrl = data['url'] ?? data['imageUrl'] ?? data['image_url'];
        
        // If not found, check nested in data object
        if ((imageUrl == null || imageUrl.isEmpty) && data['data'] != null) {
          final dataObj = data['data'];
          imageUrl = dataObj['url'] ?? 
                     dataObj['imageUrl'] ?? 
                     dataObj['ImageUrl'] ?? 
                     dataObj['image_url'];
        }
        
        print('📥 [AwsS3Service] success: ${data['success']}, found url: $imageUrl');
        
        if (data['success'] == true && imageUrl != null && imageUrl.toString().isNotEmpty) {
          print('✅ [AwsS3Service] Image uploaded successfully: $imageUrl');
          return imageUrl.toString();
        } else {
          print('❌ [AwsS3Service] Response data: $data');
          print('❌ [AwsS3Service] URL is null or empty: $imageUrl');
          throw Exception('Upload succeeded but no URL returned. Response: ${response.body}');
        }
      } else {
        // Parse error response from backend
        String errorMessage = 'Failed to upload image';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? 'Failed to upload image';
          print('❌ [AwsS3Service] Backend error: $errorMessage');
        } catch (e) {
          print('❌ [AwsS3Service] Could not parse error response: ${response.body}');
          errorMessage = 'Failed to upload image (Status: ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [AwsS3Service] Exception during upload: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      } else if (e.toString().contains('Authentication') || e.toString().contains('401')) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Error uploading image: ${e.toString()}');
      }
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    try {
      final urls = <String>[];
      for (var file in imageFiles) {
        final url = await uploadImage(file);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Error uploading multiple images: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract key from URL if needed
      // For now, deletion is handled by backend when service is deleted
      // This can be implemented if direct deletion is needed
    } catch (e) {
      // Silently fail - image might not exist
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Alternative: Direct S3 upload using presigned URL
  // This would require backend endpoint to generate presigned URLs
  Future<String> uploadImageDirect(File imageFile) async {
    try {
      // Step 1: Get presigned URL from backend
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/services/get-upload-url'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fileName': imageFile.path.split('/').last,
          'contentType': 'image/jpeg',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final presignedUrl = data['url'] as String;

        // Step 2: Upload to S3 using presigned URL
        final bytes = await imageFile.readAsBytes();
        final uploadResponse = await http.put(
          Uri.parse(presignedUrl),
          body: bytes,
          headers: {
            'Content-Type': 'image/jpeg',
          },
        );

        if (uploadResponse.statusCode == 200) {
          return data['publicUrl'] as String;
        } else {
          throw Exception('Failed to upload to S3');
        }
      } else {
        throw Exception('Failed to get presigned URL');
      }
    } catch (e) {
      throw Exception('Error uploading image directly: $e');
    }
  }
}

