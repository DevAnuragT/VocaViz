import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// Camera screen for capturing pump images or selecting from gallery.
class CameraScreen extends StatefulWidget {
  final Function(Uint8List imageBytes, String source) onImageCaptured;
  final VoidCallback onCancel;

  const CameraScreen({
    super.key,
    required this.onImageCaptured,
    required this.onCancel,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      // Find back camera by default
      for (var i = 0; i < _cameras!.length; i++) {
        if (_cameras![i].lensDirection == CameraLensDirection.back) {
          _currentCameraIndex = i;
          break;
        }
      }

      await _startCamera(_cameras![_currentCameraIndex]);
    } catch (e) {
      AppLogger.e('Failed to initialize camera', 'CameraScreen', e);
      _showCameraError();
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    try {
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      AppLogger.e('Failed to start camera', 'CameraScreen', e);
      _showCameraError();
    }
  }

  Future<void> _captureImage() async {
    if (_isProcessing || !_isCameraInitialized) return;

    setState(() => _isProcessing = true);

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();

      widget.onImageCaptured(bytes, 'camera');
    } catch (e) {
      AppLogger.e('Failed to capture image', 'CameraScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        widget.onImageCaptured(bytes, 'gallery');
      }
    } catch (e) {
      AppLogger.e('Failed to pick image', 'CameraScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to select image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showCameraError() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Error'),
        content: const Text('Unable to access camera. Please check permissions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel();
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: Transform.scale(
                scale: 1.0,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onCancel,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Point at water pump',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureImage,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                    ),

                    // Placeholder for balance
                    const SizedBox(width: 60),
                  ],
                ),
              ),
            ),
          ),

          // Instruction overlay
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Center the belt and pulleys',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
