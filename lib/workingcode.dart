
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
      home: OdometerReaderScreen(cameras: cameras),
    );
  }
}

class OdometerReaderScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  OdometerReaderScreen({required this.cameras});

  @override
  _OdometerReaderScreenState createState() => _OdometerReaderScreenState();
}

class _OdometerReaderScreenState extends State<OdometerReaderScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  String _extractedNumber = '';
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
    );
    await _cameraController.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _captureAndProcessImage() async {
    if (!_isCameraInitialized) return;
    try {
      final XFile imageFile = await _cameraController.takePicture();
      final processedImagePath = await _preprocessImage(imageFile.path);
      final inputImage = InputImage.fromFilePath(processedImagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract 6-8 digit numbers using RegExp
      final numberRegExp = RegExp(r'\b\d{6,8}\b');
      final matches = numberRegExp.allMatches(recognizedText.text);

      if (matches.isNotEmpty) {
        setState(() {
          _extractedNumber = matches.map((m) => m.group(0)).join(', ');
        });
      } else {
        setState(() {
          _extractedNumber = 'No 6-8 digit number found';
        });
      }
    } catch (e) {
      setState(() {
        _extractedNumber = 'Error: ${e.toString()}';
      });
    }
  }

  Future<String> _preprocessImage(String imagePath) async {
    // Load the image
    final originalImage = img.decodeImage(File(imagePath).readAsBytesSync());

    // Convert to grayscale
    final grayscaleImage = img.grayscale(originalImage!);

    // Apply thresholding
    // final thresholdImage = img.threshold(grayscaleImage, threshold: 128);

    // Save the processed image
    final processedImagePath = '${imagePath}_processed.png';
    File(processedImagePath).writeAsBytesSync(img.encodePng(grayscaleImage));

    return processedImagePath;
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
      appBar: AppBar(
        title: Text('Odometer Reader'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 550,
                     child: CameraPreview(_cameraController),
          ),  
          SizedBox(height: 16),
         
          ElevatedButton(
            onPressed: _captureAndProcessImage,
            child: Text('Capture and Extract Number'),
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Extracted Number: $_extractedNumber',
            style: TextStyle(fontSize: 16),
          ),
          
        ],
      ),
    );
  }
}
