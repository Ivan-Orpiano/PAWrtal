import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class WebImagePickerService {
  static Future<ImagePickerResult?> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important for web to get bytes
      );

      if (result != null && result.files.single.bytes != null) {
        PlatformFile file = result.files.single;
        
        // For web, we work with bytes
        if (kIsWeb) {
          return ImagePickerResult.fromBytes(
            bytes: file.bytes!,
            name: file.name,
          );
        } 
        // For desktop, we can still use file path
        else if (file.path != null) {
          return ImagePickerResult.fromFile(
            file: File(file.path!),
            name: file.name,
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