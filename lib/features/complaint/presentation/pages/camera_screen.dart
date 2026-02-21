import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  final bool _isTakingPicture = false;


  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      print("Camera error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Capture Garbage")),
      body: _isCameraReady
          ? Stack(
        children: [
          CameraPreview(_controller!),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: () async {
                  final image = await _controller!.takePicture();

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PreviewScreen(imagePath: image.path),
                    ),
                  );
                },


                child: const Icon(Icons.camera),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),

    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
