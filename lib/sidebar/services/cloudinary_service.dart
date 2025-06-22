import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String uploadPreset = 'YOUR_UPLOAD_PRESET';
  static const String apiKey = 'YOUR_API_KEY';
  
  static Future<String?> uploadImage(File imageFile, {String folder = 'heartbite'}) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      
      final file = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(file);
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      }
      
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
