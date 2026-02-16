import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class PlatformImageService {
  static final ImagePicker _picker = ImagePicker();

  // Pick images that work on both mobile and web
  static Future<List<XFile>> pickImages({int? maxImages}) async {
    try {
      if (kIsWeb) {
        // For web, we can only pick one image at a time
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
        );
        return image != null ? [image] : [];
      } else {
        // For mobile, we can pick multiple images
        final List<XFile> images = await _picker.pickMultiImage();
        if (maxImages != null && images.length > maxImages) {
          return images.take(maxImages).toList();
        }
        return images;
      }
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  // Pick single image
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      return await _picker.pickImage(source: source);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Convert XFile to bytes for web compatibility
  static Future<Uint8List> getImageBytes(XFile image) async {
    try {
      return await image.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read image bytes: $e');
    }
  }

  // Get image size
  static Future<Map<String, int>> getImageSize(XFile image) async {
    try {
      if (kIsWeb) {
        // For web, we need to decode the image to get dimensions
        // This is a simplified approach - in production you might want to use a proper image decoder
        return {'width': 0, 'height': 0}; // Placeholder
      } else {
        // For mobile, we can get file info
        final file = File(image.path);
        if (await file.exists()) {
          // You can use packages like 'image' to get actual dimensions
          return {'width': 0, 'height': 0}; // Placeholder
        }
        return {'width': 0, 'height': 0};
      }
    } catch (e) {
      return {'width': 0, 'height': 0};
    }
  }

  // Check if camera is available
  static Future<bool> isCameraAvailable() async {
    try {
      if (kIsWeb) {
        // Web camera availability check
        return true; // Simplified - in production you'd check actual camera availability
      } else {
        // Mobile camera availability check
        return await _picker.pickImage(source: ImageSource.camera) != null;
      }
    } catch (e) {
      return false;
    }
  }
}
