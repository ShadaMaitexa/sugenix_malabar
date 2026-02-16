import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  // Use a singleton or static instance to avoid creating multiple recognizers
  static final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from an image using ML Kit (On-Device, No API required)
  static Future<String> extractText(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to extract text using OCR: $e');
    }
  }

  /// Close the recognizer resources
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
