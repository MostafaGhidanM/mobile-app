import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class ImagePickerWidget extends StatelessWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final String label;
  final Function(dynamic) onImagePicked; // Can be File or Uint8List
  final Function(Map<String, double>)? onLocationCaptured; // Optional location callback
  final IconData icon;
  final String? helperText;
  final bool captureLocation; // Whether to automatically capture location

  const ImagePickerWidget({
    Key? key,
    this.imagePath,
    this.imageBytes,
    required this.label,
    required this.onImagePicked,
    this.onLocationCaptured,
    this.icon = Icons.camera_alt,
    this.helperText,
    this.captureLocation = false,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    // Capture location first if enabled
    Map<String, double>? location;
    if (captureLocation && !kIsWeb) {
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Force open location settings
          await Geolocator.openLocationSettings();
          // Wait a bit and check again
          await Future.delayed(const Duration(milliseconds: 500));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }

        if (serviceEnabled) {
          // Check location permissions
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          
          if (permission == LocationPermission.deniedForever) {
            // Open app settings to enable location permission
            await Geolocator.openAppSettings();
            await Future.delayed(const Duration(milliseconds: 500));
            permission = await Geolocator.checkPermission();
          }
          
          if (permission == LocationPermission.whileInUse || 
              permission == LocationPermission.always) {
            try {
              Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 5),
              );
              location = {
                'lat': position.latitude,
                'lng': position.longitude,
              };
              if (onLocationCaptured != null) {
                onLocationCaptured!(location!);
              }
            } catch (e) {
              // Continue without location if capture fails
            }
          }
        }
      } catch (e) {
        // Continue without location if there's an error
      }
    }

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

