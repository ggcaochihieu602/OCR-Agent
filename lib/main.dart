import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:translator_plus/translator_plus.dart';

// IMPORT THÊM CHAT SCREEN
import 'chat_screen.dart';

// 1. GLOBAL CAMERA LIST INITIALIZATION
// This list holds the available cameras on the device.
late List<CameraDescription> _cameras;

Future<void> main() async {
  // Ensure that plugin services are initialized before using them.
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  try {
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    // Handle error if no cameras are found or permissions are denied
    print('Error accessing cameras: $e');
    _cameras = []; // Set to empty if error occurs
  }

  runApp(const MyApp());

  final translator = GoogleTranslator();

  final input = "Xin chao toi den tu Viet Nam";

  // The rest of the main function's example code remains the same...
  translator.translate(input, from: 'vi', to: 'en').then(print);
  // prints Hello. Are you okay?

  var translation = await translator.translate(
    "Xin chào, tôi đến từ Việt Nam",
    to: 'en',
  );
  print(translation);
  // prints Hello, I come from Vietnam

  print(await "example".translate(to: 'pt'));
  // prints exemplo
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Pass the list of cameras to the home screen
      home: MyHomePage(title: 'OCR Scanner', cameras: _cameras),
    );
  }
}

// 2. MAIN OCR VIEW
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.cameras});

  final String title;
  final List<CameraDescription> cameras;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _imageFile;
  String _extractedText = 'Select an image or take a picture to begin OCR.';
  bool _isProcessing = false;
  String _translatedText = "Translation";
  bool _isTranslating = false;
  final translator = GoogleTranslator();

  // --- NEW: Language Selection Variables ---
  // A map of friendly names to language codes
  final Map<String, String> _languages = {
    'Vietnamese': 'vi',
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Japanese': 'ja',
  };

  // State to hold the currently selected language code (defaulting to Vietnamese)
  String _selectedTargetLanguageCode = 'vi';

  // --- Image Picking and Processing Logic ---

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      await _processImage(File(pickedFile.path));
    }
  }

  Future<void> _takePicture() async {
    // Check if any cameras are available
    if (widget.cameras.isEmpty) {
      setState(() {
        _extractedText = 'Error: No cameras available on this device.';
      });
      return;
    }

    // Navigate to the CameraScreen to capture the image
    final String? imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: widget.cameras.first),
      ),
    );

    // If an image path is returned, process it
    if (imagePath != null) {
      await _processImage(File(imagePath));
    }
  }

  Future<void> _processImage(File image) async {
    setState(() {
      _imageFile = image;
      _extractedText = 'Processing image...';
      _isProcessing = true;
      // Reset translation when a new image is processed
      _translatedText = "Translation";
    });

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    // Dispose the recognizer to free up resources
    textRecognizer.close();

    setState(() {
      _extractedText = recognizedText.text.isEmpty
          ? 'Could not recognize any text.'
          : recognizedText.text;
      _isProcessing = false;
      _extractedText = recognizedText.text;
    });
  }

  // --- MODIFIED: Translation Logic to use selected target language ---
  Future<void> _translateText(String extractedText) async {
    // Only translate if there's actual text and not the placeholder or error message
    if (extractedText.isEmpty ||
        extractedText.contains('Select an image') ||
        extractedText.contains('Could not recognize')) {
      setState(() {
        _translatedText = "No valid text to translate.";
      });
      return;
    }

    setState(() {
      _translatedText =
          "Translating to ${_languages.entries.firstWhere((e) => e.value == _selectedTargetLanguageCode).key}...";
      _isTranslating = true;
    });

    try {
      // Use the stored _selectedTargetLanguageCode for translation
      var google_translation = await translator.translate(
        extractedText,
        to: _selectedTargetLanguageCode,
      );

      setState(() {
        _translatedText = google_translation.text;
        _isTranslating = false;
      });
    } catch (e) {
      print('Translation error: $e');
      setState(() {
        _translatedText = "Error during translation.";
        _isTranslating = false;
      });
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Image Display (Unchanged)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 200,
                child: _imageFile == null
                    ? Center(
                        child: Text(
                          'No image selected.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 30),

              // Button 1: Gallery (Unchanged)
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Select from Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 15),

              // Button 2: Camera (Unchanged)
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Picture'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 15),

              // --- NEW: Language Selector and Translate Button in a Row ---
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedTargetLanguageCode,
                          icon: const Icon(Icons.arrow_drop_down),
                          elevation: 16,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedTargetLanguageCode = newValue;
                                // Reset translated text when language changes
                                _translatedText = "Translation target changed.";
                              });
                            }
                          },
                          items: _languages.entries
                              .map<DropdownMenuItem<String>>(
                                  (MapEntry<String, String> entry) {
                            return DropdownMenuItem<String>(
                              value: entry.value,
                              child: Text(
                                'Translate to: ${entry.key}',
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Button 3: Translate
                  ElevatedButton.icon(
                    onPressed: _isProcessing || _isTranslating
                        ? null
                        : () {
                            _translateText(_extractedText);
                          },
                    icon: _isTranslating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.translate),
                    label: Text(
                      _isTranslating ? 'Translating...' : 'Translate',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              // --- END NEW: Language Selector and Translate Button in a Row ---
              const SizedBox(height: 40),

              // Extracted Text Display (Unchanged)
              const Text(
                'Extracted Text:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                constraints: const BoxConstraints(minHeight: 100),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : SelectableText(
                        _extractedText,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),

              // Translated Text Display (Unchanged)
              const SizedBox(height: 20),
              const Text(
                'Translated Text:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                constraints: const BoxConstraints(minHeight: 100),
                child: _isTranslating
                    ? const Center(child: CircularProgressIndicator())
                    : SelectableText(
                        _translatedText,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),

              // ===== NÚT MỚI MỞ CHATBOT =====
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.smart_toy),
                label: const Text('Chat với AI'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. SEPARATE CAMERA PREVIEW VIEW (Unchanged)
class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the controller.
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      // Ensure the camera is initialized.
      await _initializeControllerFuture;

      // Attempt to take a picture.
      final image = await _controller.takePicture();

      if (!context.mounted) return;

      // Pop back to MyHomePage, passing the image path back as the result.
      Navigator.pop(context, image.path);
    } catch (e) {
      print('Error taking picture: $e');
      if (context.mounted) {
        // Show an error message before popping
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to take picture.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a Picture')),
      // Use FutureBuilder to display the camera preview once initialized.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureImage,
        child: const Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
