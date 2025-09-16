import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class WebImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<ImagePickerResult?> pickImage() async {
    try {
      final XFile? result = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,  // Optional: limit image size
        maxHeight: 1080, // Optional: limit image size
      );

      if (result != null) {
        final String name = result.name;
        
        // For web, we work with bytes
        if (kIsWeb) {
          final bytes = await result.readAsBytes();
          return ImagePickerResult.fromBytes(
            bytes: bytes,
            name: name,
          );
        } 
        // For mobile/desktop, we can use file path
        else {
          return ImagePickerResult.fromFile(
            file: File(result.path),
            name: name,
          );
        }
      }
    } catch (e) {
      print("Error picking image: $e");
    }
    return null;
  }
}

class ImagePickerResult {
  final File? file;
  final Uint8List? bytes;
  final String name;

  ImagePickerResult._({
    this.file,
    this.bytes,
    required this.name,
  });

  factory ImagePickerResult.fromFile({
    required File file,
    required String name,
  }) {
    return ImagePickerResult._(
      file: file,
      name: name,
    );
  }

  factory ImagePickerResult.fromBytes({
    required Uint8List bytes,
    required String name,
  }) {
    return ImagePickerResult._(
      bytes: bytes,
      name: name,
    );
  }

  bool get isWeb => kIsWeb && bytes != null;
  bool get isFile => file != null;
}