// import 'dart:io';
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:opencv_4/factory/pathfrom.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:opencv_4/opencv_4.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final cameras = await availableCameras();
//   runApp(MyApp(cameras: cameras));
// }

// class MyApp extends StatelessWidget {
//   final List<CameraDescription> cameras;
//   const MyApp({super.key, required this.cameras});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Odometer Reader',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: OdometerReaderScreen(cameras: cameras),
//     );
//   }
// }

// class OdometerReaderScreen extends StatefulWidget {
//   final List<CameraDescription> cameras;
//   const OdometerReaderScreen({super.key, required this.cameras});

//   @override
//   _OdometerReaderScreenState createState() => _OdometerReaderScreenState();
// }

// class _OdometerReaderScreenState extends State<OdometerReaderScreen> {
//   late CameraController _cameraController;
//   bool _isCameraInitialized = false;
//   String _extractedNumber = '';
//   final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
//   File? _processedImageFile;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   Future<void> _initializeCamera() async {
//     _cameraController = CameraController(
//       widget.cameras.first,
//       ResolutionPreset.high,
//     );
//     try {
//       await _cameraController.initialize();
//       if (!mounted) return;
//       setState(() {
//         _isCameraInitialized = true;
//       });
//     } catch (e) {
//       print('Error initializing camera: $e');
//     }
//   }

// Future<String> _preprocessImage(String imagePath) async {
//   // Convert image to grayscale
//   final Uint8List? grayImageData = await Cv2.cvtColor(
//     pathFrom: CVPathFrom.GALLERY_CAMERA,
//     pathString: imagePath,
//     outputType: Cv2.COLOR_BGR2GRAY,
//   );

//   if (grayImageData == null) {
//     throw Exception('Failed to convert image to grayscale');
//   }

//   // Save the grayscale image to a temporary file
//   final tempDir = await getTemporaryDirectory();
//   final grayImagePath = '${tempDir.path}/gray_image.png';
//   final grayImageFile = File(grayImagePath);
//   await grayImageFile.writeAsBytes(grayImageData);

//   // Apply adaptive thresholding
//   final Uint8List? thresholdedImageData = await Cv2.adaptiveThreshold(
//     pathFrom: CVPathFrom.GALLERY_CAMERA,
//     pathString: grayImagePath,
//     maxValue: 255,
//     adaptiveMethod: Cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
//     thresholdType: Cv2.THRESH_BINARY,
//     blockSize: 11,
//     constantValue: 2,
//   );

//   if (thresholdedImageData == null) {
//     throw Exception('Failed to apply adaptive thresholding');
//   }

//   // Save the thresholded image to a temporary file
//   final processedImagePath = '${tempDir.path}/processed_image.png';
//   final processedImageFile = File(processedImagePath);
//   await processedImageFile.writeAsBytes(thresholdedImageData);

//   return processedImagePath;
// }


//   Future<void> _captureAndProcessImage() async {
//     if (!_isCameraInitialized) return;

//     try {
//       // Capture image
//       final XFile imageFile = await _cameraController.takePicture();

//       // Preprocess the image
//       final processedImagePath = await _preprocessImage(imageFile.path);
//       setState(() {
//         _processedImageFile = File(processedImagePath);
//       });

//       // Perform text recognition
//       final inputImage = InputImage.fromFilePath(processedImagePath);
//       final recognizedText = await _textRecognizer.processImage(inputImage);

//       // Extract 6-8 digit numbers using RegExp
//       final numberRegExp = RegExp(r'\b\d{6,8}\b');
//       final matches = numberRegExp.allMatches(recognizedText.text);

//       if (matches.isNotEmpty) {
//         setState(() {
//           _extractedNumber = matches.map((m) => m.group(0)).join(', ');
//         });
//       } else {
//         // Fallback: try to extract any continuous sequence of digits
//         final digitSequence = RegExp(r'\d+').allMatches(recognizedText.text);
//         if (digitSequence.isNotEmpty) {
//           setState(() {
//             _extractedNumber = digitSequence.map((m) => m.group(0)).join(', ');
//           });
//         } else {
//           setState(() {
//             _extractedNumber = 'No number found';
//           });
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _extractedNumber = 'Error: ${e.toString()}';
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _cameraController.dispose();
//     _textRecognizer.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Odometer Reader'),
//       ),
//       body: Column(
//         children: [
//           // Camera Preview
//           _isCameraInitialized
//               ? Container(
//                   width: double.infinity,
//                   height: 400,
//                   child: CameraPreview(_cameraController),
//                 )
//               : const CircularProgressIndicator(),

//           const SizedBox(height: 16),

//           // Processed Image Preview (if available)
//           if (_processedImageFile != null)
//             Container(
//               width: 200,
//               height: 200,
//               child: Image.file(_processedImageFile!),
//             ),

//           const SizedBox(height: 16),

//           // Capture Button
//           ElevatedButton(
//             onPressed: _captureAndProcessImage,
//             child: const Text('Capture and Extract Number'),
//           ),

//           const SizedBox(height: 16),

//           // Extracted Number Display
//           Text(
//             'Extracted Number: $_extractedNumber',
//             style: const TextStyle(fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }
// }
