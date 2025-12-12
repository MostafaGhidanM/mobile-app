import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class UploadService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<UploadResponse>> uploadImage(dynamic imageData) async {
    if (kIsWeb && imageData is Uint8List) {
      // On web, compress bytes directly
      final compressedBytes = await _compressImageBytes(imageData);
      return await _apiClient.uploadBytes<UploadResponse>(
        ApiEndpoints.uploadImage,
        compressedBytes,
        fieldName: 'file',
        fromJson: (json) => UploadResponse.fromJson(json as Map<String, dynamic>),
      );
    } else if (!kIsWeb && imageData is File) {
      // On mobile, compress file
      final compressedFile = await _compressImage(imageData);
      return await _apiClient.uploadFile<UploadResponse>(
        ApiEndpoints.uploadImage,
        compressedFile.path,
        fieldName: 'file',
        fromJson: (json) => UploadResponse.fromJson(json as Map<String, dynamic>),
      );
    } else {
      return ApiResponse<UploadResponse>(
        success: false,
        error: ApiError(
          code: 'INVALID_TYPE',
          message: 'Invalid image data type',
        ),
      );
    }
  }

  Future<Uint8List> _compressImageBytes(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      
      if (image == null) return bytes;
      
      // Check file size (8MB = 8 * 1024 * 1024 bytes)
      const maxSize = 8 * 1024 * 1024;
      if (bytes.length <= maxSize) {
        return bytes; // No compression needed
      }

      // Calculate compression ratio
      final ratio = maxSize / bytes.length;
      final quality = (ratio * 100).round().clamp(50, 95);

      // Resize if too large (max 1920px on longest side)
      img.Image? processedImage = image;
      if (image.width > 1920 || image.height > 1920) {
        final scale = 1920 / (image.width > image.height ? image.width : image.height);
        processedImage = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
      }

      // Encode with compression
      return Uint8List.fromList(img.encodeJpg(processedImage, quality: quality));
    } catch (e) {
      // If compression fails, return original bytes
      return bytes;
    }
  }

  Future<File> _compressImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return imageFile;
      
      // Check file size (8MB = 8 * 1024 * 1024 bytes)
      const maxSize = 8 * 1024 * 1024;
      if (bytes.length <= maxSize) {
        return imageFile; // No compression needed
      }

      // Calculate compression ratio
      final ratio = maxSize / bytes.length;
      final quality = (ratio * 100).round().clamp(50, 95);

      // Resize if too large (max 1920px on longest side)
      img.Image? processedImage = image;
      if (image.width > 1920 || image.height > 1920) {
        final scale = 1920 / (image.width > image.height ? image.width : image.height);
        processedImage = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
      }

      // Encode with compression
      final compressedBytes = img.encodeJpg(processedImage, quality: quality);
      
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);
      
      return tempFile;
    } catch (e) {
      // If compression fails, return original file
      return imageFile;
    }
  }
}

class UploadResponse {
  final String url;
  final String filename;

  UploadResponse({
    required this.url,
    required this.filename,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      url: json['data']?['url'] ?? json['url'] ?? '',
      filename: json['data']?['filename'] ?? json['filename'] ?? '',
    );
  }
}

