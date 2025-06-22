import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  
  // Upload image from bytes (works on all platforms)
  static Future<String?> uploadImageFromBytes(
    Uint8List imageBytes,
    String fileName, {
    String folder = 'heartbite',
  }) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      
      // Create multipart file from bytes
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      );
      
      request.files.add(multipartFile);
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Alternative method using base64 (simpler but less efficient for large images)
  static Future<String?> uploadImageBase64(
    Uint8List imageBytes, {
    String folder = 'heartbite',
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final dataUri = 'data:image/jpeg;base64,$base64Image';
      
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final response = await http.post(
        url,
        body: {
          'file': dataUri,
          'upload_preset': uploadPreset,
          'folder': folder,
        },
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['secure_url'];
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
