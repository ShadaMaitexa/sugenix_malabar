import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'dpfhr81ee';
  static const String _uploadPreset = 'sugenix';

  // Upload single image
  static Future<String> uploadImage(XFile imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      request.fields['upload_preset'] = _uploadPreset;
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'] as String;
      } else {
        throw Exception('Failed to upload image: ${jsonData['error']}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple images
  static Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    try {
      List<String> imageUrls = [];

      for (var imageFile in imageFiles) {
        final url = await uploadImage(imageFile);
        imageUrls.add(url);
      }

      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Get optimized URL
  static String getOptimizedUrl(String imageUrl, {int width = 800}) {
    if (imageUrl.contains('cloudinary.com')) {
      // Insert transformation parameters before the file extension
      final parts = imageUrl.split('/upload/');
      if (parts.length > 1) {
        return '${parts[0]}/upload/c_limit,w_$width/${parts[1]}';
      }
    }
    return imageUrl;
  }
}
