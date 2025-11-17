import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:arkit_plugin_example/util/ar_helper.dart';
import 'package:flutter/material.dart';

class HDRCapturePage extends StatefulWidget {
  const HDRCapturePage({super.key});

  @override
  State<HDRCapturePage> createState() => _HDRCapturePageState();
}

class _HDRCapturePageState extends State<HDRCapturePage> {
  late ARKitController arkitController;
  bool isCapturing = false;

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('HDR Capture'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isCapturing ? Colors.grey : Colors.blue,
        onPressed: isCapturing ? null : () async {
          setState(() {
            isCapturing = true;
          });

          try {
            final filePath = await arkitController.captureHDRImage();
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HDRImagePreview(
                  filePath: filePath,
                ),
              ),
            );
          } catch (e) {
            debugPrint('HDR Capture Error: $e');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('HDR capture failed: $e')),
            );
          } finally {
            if (mounted) {
              setState(() {
                isCapturing = false;
              });
            }
          }
        },
        child: isCapturing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.camera_enhance),
      ),
      body: ARKitSceneView(onARKitViewCreated: onARKitViewCreated));

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.add(createSphere());
  }
}

class HDRImagePreview extends StatelessWidget {
  const HDRImagePreview({
    super.key,
    required this.filePath,
  });

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HDR Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('HDR Image Info'),
                  content: Text(
                    'HDR image saved as OpenEXR format:\n\n'
                    '• File path: $filePath\n'
                    '• Format: Binary HDR data\n'
                    '• Color space: Extended linear sRGB\n'
                    '• Channels: RGBA (float32)\n'
                    '• No processing applied (raw data)'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            Text('HDR Image Saved', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                filePath,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'OpenEXR format file cannot be displayed directly.\n'
              'Use external tools to view or convert the HDR data.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}