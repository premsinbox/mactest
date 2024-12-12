import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odometer Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OdometerScanner(cameras: cameras),
    );
  }
}

class OdometerScanner extends StatefulWidget {
  final List<CameraDescription> cameras;

  const OdometerScanner({Key? key, required this.cameras}) : super(key: key);

  @override
  State<OdometerScanner> createState() => _OdometerScannerState();
}

class _OdometerScannerState extends State<OdometerScanner> {
  late CameraController _cameraController;
  late TextRecognizer _textRecognizer;
  bool _isProcessing = false;
  String _odometerValue = "Scanning...";
  final GlobalKey _cameraKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
    );

    await _cameraController.initialize();
    setState(() {});
  }

  /// Crop the region within the rectangle
  Future<File> _cropToRectangle(File imageFile) async {
    final RenderBox renderBox = _cameraKey.currentContext!.findRenderObject() as RenderBox;
    final double rectWidth = renderBox.size.width * 0.8;
    final double rectHeight = renderBox.size.height * 0.2;
    final double rectX = (renderBox.size.width - rectWidth) / 2;
    final double rectY = (renderBox.size.height - rectHeight) / 2;

    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception("Failed to decode image");

    // Convert rectangle coordinates to image scale
    final scaleX = image.width / renderBox.size.width;
    final scaleY = image.height / renderBox.size.height;

    final int cropX = (rectX * scaleX).toInt();
    final int cropY = (rectY * scaleY).toInt();
    final int cropWidth = (rectWidth * scaleX).toInt();
    final int cropHeight = (rectHeight * scaleY).toInt();

    final img.Image croppedImage = img.copyCrop(image, x:cropX, y:cropY, width:cropWidth,height: cropHeight);
    final croppedFile = File('${imageFile.path}_cropped.jpg');
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));
    return croppedFile;
  }
Future<void> _scanOdometer() async {
  if (_isProcessing) return;
  setState(() => _isProcessing = true);

  try {
    // Capture Image
    final XFile imageFile = await _cameraController.takePicture();
    final File croppedFile = await _cropToRectangle(File(imageFile.path));

    // Recognize Text
    final inputImage = InputImage.fromFilePath(croppedFile.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // Extract numbers using regex
    final RegExp odometerRegex = RegExp(r'^\d{6,8}$');
    final odometerMatches = recognizedText.blocks
        .map((block) => block.text)
        .where((text) => odometerRegex.hasMatch(text))
        .toList();

    final odometerValue = odometerMatches.isNotEmpty
        ? odometerMatches.join(', ')
        : "No odometer value found";

    setState(() => _odometerValue = odometerValue);
  } catch (e) {
    setState(() => _odometerValue = "Error: ${e.toString()}");
  }

  setState(() => _isProcessing = false);
}

  @override
  void dispose() {
    _cameraController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Odometer Scanner")),
      body: Stack(
        children: [
          if (_cameraController.value.isInitialized)
            SizedBox(
              key: _cameraKey,
              height: MediaQuery.of(context).size.height,
              child: CameraPreview(_cameraController),
            ),
          // Rectangle Overlay
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
              ),
            ),
          ),
          // Capture Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _scanOdometer,
                child: const Text("Scan Odometer"),
              ),
            ),
          ),
          // Odometer Value Display
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Odometer Value: $_odometerValue",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
