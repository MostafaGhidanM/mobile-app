import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatelessWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final String label;
  final Function(dynamic) onImagePicked; // Can be File or Uint8List
  final IconData icon;
  final String? helperText;

  const ImagePickerWidget({
    Key? key,
    this.imagePath,
    this.imageBytes,
    required this.label,
    required this.onImagePicked,
    this.icon = Icons.camera_alt,
    this.helperText,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      if (kIsWeb) {
        // On web, read bytes directly
        final bytes = await image.readAsBytes();
        onImagePicked(bytes);
      } else {
        // On mobile, use File
        onImagePicked(File(image.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(context),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: (imagePath != null || imageBytes != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb && imageBytes != null
                        ? Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                          )
                        : !kIsWeb && imagePath != null
                            ? Image.file(
                                File(imagePath!),
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Take a picture',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (helperText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          helperText!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

