import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUploadService {
  // Static instance for CloudinaryPublic using values from .env
  // This assumes .env is loaded at app startup (e.g., in main.dart)
  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'YOUR_FALLBACK_CLOUD_NAME', // Fallback if not in .env
    dotenv.env['CLOUDINARY_API_KEY'] ?? 'YOUR_FALLBACK_API_KEY',       // Fallback if not in .env
    cache: false, // Default is true, set to false if you don't want caching for some reason
  );

  // Method to upload an image
  // Takes the image file and an optional upload preset name
  Future<String?> uploadImage(File imageFile, {String? customUploadPreset}) async {
    // Determine the upload preset to use:
    // 1. Use customUploadPreset if provided
    // 2. Else, try to get CLOUDINARY_UPLOAD_PRESET from .env
    // 3. Else, fallback to a common default like 'ml_default' (Cloudinary's default unsigned preset)
    final String uploadPreset = customUploadPreset ??
                                dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ??
                                'ml_default';

    print("Attempting to upload image: ${imageFile.path} using preset: $uploadPreset");
    print("Ensure your Cloudinary Upload Preset ('$uploadPreset') is configured to use your desired folder.");

    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
        uploadPreset: uploadPreset, // This is the primary way to pass the preset
        // For cloudinary_public with unsigned uploads, 'folder' and 'public_id' are best managed
        // within the Upload Preset settings on your Cloudinary dashboard.
        // Passing them directly here with unsigned uploads might be ignored or cause issues
        // depending on strictness of preset and SDK version.
      );

      // For cloudinary_public v0.23.1, success is typically when secureUrl is available.
      // Errors usually result in a CloudinaryException.
      if (response.secureUrl != null && response.secureUrl!.isNotEmpty) {
        print("Image uploaded successfully. URL: ${response.secureUrl}");
        return response.secureUrl;
      } else {
        // This case might indicate an issue if no exception was thrown but also no URL was returned.
        print("Image upload did not return a secure URL, though no direct exception was caught.");
        print("Public ID: ${response.publicId}"); // Log public_id if available for debugging
        print("Response details (if any): ${response.toString()}"); // General response details
        return null;
      }
    } on CloudinaryException catch (e) { // Catching specific SDK exception
      print("Cloudinary API Exception during upload: ${e.message}");
      // The CloudinaryException object might have more details depending on the SDK version
      // For example, e.response?.data or e.toString()
      print("Details: ${e.toString()}"); 
      return null;
    } catch (e) {
      print("Generic error during image upload: $e");
      return null;
    }
  }
}

// How to use in your widget:
// final ImageUploadService _imageUploadService = ImageUploadService();
// String? imageUrl = await _imageUploadService.uploadImage(myImageFile);
// // To use a specific preset (if CLOUDINARY_UPLOAD_PRESET in .env is not what you want for this call):
// // String? imageUrl = await _imageUploadService.uploadImage(myImageFile, customUploadPreset: "my_other_preset");
