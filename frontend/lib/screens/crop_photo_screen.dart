import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import '../theme/app_theme.dart';

class CropPhotoScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropPhotoScreen({super.key, required this.imageBytes});

  @override
  State<CropPhotoScreen> createState() => _CropPhotoScreenState();
}

class _CropPhotoScreenState extends State<CropPhotoScreen> {
  final CropController _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Adjust Photo'),
        actions: [
          TextButton(
            onPressed: _isCropping
                ? null
                : () {
                    setState(() => _isCropping = true);
                    _cropController.crop();
                  },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Crop(
        controller: _cropController,
        image: widget.imageBytes,
        aspectRatio: 1,
        withCircleUi: false,
        baseColor: Colors.black,
        maskColor: Colors.black.withValues(alpha: 0.6),
        cornerDotBuilder: (size, edgeAlignment) => const SizedBox.shrink(),
        onCropped: (result) {
          if (result is CropSuccess) {
            Navigator.of(context).pop(result.croppedImage);
          } else {
            Navigator.of(context).pop(null);
          }
        },
      ),
    );
  }
}
