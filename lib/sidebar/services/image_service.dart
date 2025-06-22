import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Pick image and return bytes (works on all platforms)
  static Future<Uint8List?> pickImageAsBytes(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (image != null) {
        return await image.readAsBytes();
      }
      
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Resize image bytes (optional, for better performance)
  static Uint8List? resizeImageBytes(Uint8List bytes, {int maxWidth = 800}) {
    // For now, return original bytes
    // You can add image resizing library like 'image' package here
    return bytes;
  }

  // Get file extension from bytes
  static String getFileExtension(Uint8List bytes) {
    // Simple detection based on file signature
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg';
      if (bytes[0] == 0x89 && bytes[1] == 0x50) return 'png';
      if (bytes[0] == 0x47 && bytes[1] == 0x49) return 'gif';
    }
    return 'jpg'; // default
  }

  // Generate filename
  static String generateFileName(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp';
  }
}
