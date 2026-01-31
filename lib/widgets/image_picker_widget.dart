import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../localization/app_localizations.dart';

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
    // When location is required for this photo, enforce it before opening camera
    if (captureLocation && !kIsWeb) {
      final l10n = AppLocalizations.of(context);
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted && l10n != null) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.enableLocationServices),
              content: Text(l10n.locationServicesRequiredCapture),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.translate('cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await Geolocator.openLocationSettings();
                  },
                  child: Text(l10n.translate('settings') ?? 'Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted && l10n != null) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.enableLocationPermission),
              content: Text(l10n.locationPermissionRequired),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.translate('cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await Geolocator.openAppSettings();
                  },
                  child: Text(l10n.translate('settings') ?? 'Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        final location = <String, double>{
          'lat': position.latitude,
          'lng': position.longitude,
        };
        onLocationCaptured?.call(location);
      } catch (_) {
        if (context.mounted && l10n != null) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.pleaseEnableLocationServices),
              content: Text(l10n.failedToGetLocation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.translate('ok') ?? 'OK'),
                ),
              ],
            ),
          );
        }
        return;
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

