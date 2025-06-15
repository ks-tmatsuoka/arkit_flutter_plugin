import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:arkit_plugin_example/util/ar_helper.dart';
import 'package:flutter/material.dart';

class HDRCapturePage extends StatefulWidget {
  @override
  _HDRCapturePageState createState() => _HDRCapturePageState();
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
        child: isCapturing 
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(Icons.camera_enhance),
        onPressed: isCapturing ? null : () async {
          setState(() {
            isCapturing = true;
          });
          
          try {
            final image = await arkitController.captureHDRImage();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HDRImagePreview(
                  imageProvider: image,
                ),
              ),
            );
          } catch (e) {
            print('HDR Capture Error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('HDR capture failed: $e')),
            );
          } finally {
            setState(() {
              isCapturing = false;
            });
          }
        },
      ),
      body: Container(
        child: ARKitSceneView(onARKitViewCreated: onARKitViewCreated),
      ));

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.add(createSphere());
  }
}

class HDRImagePreview extends StatelessWidget {
  const HDRImagePreview({
    Key? key,
    required this.imageProvider,
  }) : super(key: key);

  final ImageProvider imageProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HDR Image Preview'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('HDR Image Info'),
                  content: Text(
                    'This image was captured using HDR processing:\n\n'
                    '• Enhanced dynamic range\n'
                    '• Improved highlight/shadow balance\n'
                    '• Increased color vibrance\n'
                    '• Maximum quality JPEG compression'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: imageProvider, fit: BoxFit.contain),
        ],
      ),
    );
  }
}