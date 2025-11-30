import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        rootBundle; // Keep for the moment, but not strictly used in the simplified method below
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:translator_plus/translator_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'
    as syncfusion; // PREFIXED to solve the PdfDocument conflict
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// IMPORT THÊM CHAT SCREEN
import 'chat_screen.dart'; // Assuming chat_screen.dart exists

// 1. GLOBAL CAMERA LIST INITIALIZATION
late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  try {
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error accessing cameras: $e');
    _cameras = [];
  }

  runApp(const MyApp());

  // Example translator usage (can be removed if not needed)
  final translator = GoogleTranslator();
  final input = "Xin chao toi den tu Viet Nam";
  translator.translate(input, from: 'vi', to: 'en').then(print);
  var translation = await translator.translate(
    "Xin chào, tôi đến từ Việt Nam",
    to: 'en',
  );
  print(translation);
  print(await "example".translate(to: 'pt'));
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
      // Set MainTranslatorScreen as the home
      home: MainTranslatorScreen(cameras: _cameras),
    );
  }
}

// =========================================================================
// NEW: MainTranslatorScreen with Tabs (Google Translate Clone UI)
// =========================================================================
class MainTranslatorScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MainTranslatorScreen({super.key, required this.cameras});

  @override
  State<MainTranslatorScreen> createState() => _MainTranslatorScreenState();
}

class _MainTranslatorScreenState extends State<MainTranslatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Text', 'Images', 'Documents', 'Websites'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Translate Clone'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _tabs.map((tabText) {
            IconData icon;
            switch (tabText) {
              case 'Text':
                icon = Icons.text_fields;
                break;
              case 'Images':
                icon = Icons.image;
                break;
              case 'Documents':
                icon = Icons.description;
                break;
              case 'Websites':
                icon = Icons.language;
                break;
              default:
                icon = Icons.error;
            }
            return Tab(icon: Icon(icon), text: tabText);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Text Tab (Placeholder)
          const TextTabContent(),
          // 2. Images Tab (Your existing MyHomePage for OCR)
          MyHomePage(title: 'OCR Scanner', cameras: widget.cameras),
          // 3. Documents Tab (Now functional with PDF extraction)
          const DocumentsTabContent(),
          // 4. Websites Tab (Placeholder)
          const WebsitesTabContent(),
        ],
      ),
    );
  }
}

// =========================================================================
// TextTabContent (Placeholder)
// =========================================================================

class TextTabContent extends StatelessWidget {
  const TextTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Language selectors (simple version)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Detect language'),
              ),
              const Icon(Icons.arrow_forward_ios),
              TextButton(
                onPressed: () {},
                child: const Text('English'),
              ), // Default target
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: const TextField(
                      maxLines: null, // Allows multiline input
                      expands: true,
                      decoration: InputDecoration(
                        hintText: 'Enter text',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50, // Light blue background
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    alignment: Alignment.topLeft,
                    child: const Text(
                      'Translation will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.mic)),
              const Text('0 / 5,000'),
              DropdownButton<String>(
                value: 'en', // Default value
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'vi', child: Text('Vietnamese')),
                ],
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =========================================================================
// DocumentsTabContent (Functional with PDF extraction and PDF creation)
// =========================================================================
class DocumentsTabContent extends StatefulWidget {
  const DocumentsTabContent({super.key});

  @override
  State<DocumentsTabContent> createState() => _DocumentsTabContentState();
}

class _DocumentsTabContentState extends State<DocumentsTabContent> {
  String _documentStatus = 'Upload a document for translation (e.g., PDF).';
  String _extractedText = '';
  String _sourceFileName = '';
  bool _isProcessing = false;
  bool _isTranslating = false;
  final translator = GoogleTranslator();

  // Language map
  final Map<String, String> _languages = {
    'Vietnamese': 'vi',
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Japanese': 'ja',
  };

  String _selectedTargetLanguageCode = 'en'; // Default target

  // Helper function to find the language name from its code
  String _getLanguageName(String code) {
    // Finds the key (language name) based on the value (language code)
    return _languages.entries
        .firstWhere(
          (entry) => entry.value == code,
          orElse: () => const MapEntry('Unknown', ''),
        )
        .key;
  }

  Future<void> _pickDocumentFile() async {
    // 1. Show processing status and open file picker
    setState(() {
      _documentStatus = 'Opening file picker...';
      _isProcessing = true;
      _extractedText = '';
      _sourceFileName = ''; // Clear file name on new attempt
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Focus only on PDF
      allowMultiple: false,
    );

    // 2. Process the picked file
    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final fileName = result.files.single.name;

      if (fileName.toLowerCase().endsWith('.pdf')) {
        setState(() {
          _sourceFileName = fileName;
          _documentStatus = 'Extracting text from PDF: $fileName';
        });
        await _extractTextFromPdf(pickedFile);
      } else {
        setState(() {
          _documentStatus = 'Please select a PDF file.';
          _isProcessing = false;
        });
      }
    } else {
      // User canceled
      setState(() {
        _documentStatus = 'File selection canceled.';
        _isProcessing = false;
      });
    }
  }

  // --- Core PDF Text Extraction Function ---
  Future<void> _extractTextFromPdf(File pdfFile) async {
    try {
      final List<int> bytes = await pdfFile.readAsBytes();
      // Use the prefixed PdfDocument here
      final syncfusion.PdfDocument document = syncfusion.PdfDocument(
        inputBytes: bytes,
      );
      final syncfusion.PdfTextExtractor extractor = syncfusion.PdfTextExtractor(
        document,
      );
      final String text = extractor.extractText();
      document.dispose();

      setState(() {
        _extractedText = text.isEmpty ? '' : text;
        _isProcessing = false;
      });

      // Trigger translation after extraction
      if (!text.isEmpty) {
        await _translateExtractedText(text);
      } else {
        setState(() {
          _documentStatus = 'No readable text found in the PDF.';
        });
      }
    } catch (e) {
      print('PDF Extraction Error: $e');
      setState(() {
        _documentStatus = 'Error processing PDF.';
        _isProcessing = false;
      });
    }
  }

  // --- Translation and PDF Creation Logic ---
  Future<void> _translateExtractedText(String textToTranslate) async {
    setState(() {
      _documentStatus =
          'Translating content to ${_getLanguageName(_selectedTargetLanguageCode)}...';
      _isTranslating = true;
    });

    try {
      var translation = await translator.translate(
        textToTranslate,
        to: _selectedTargetLanguageCode,
      );

      // --- PDF Generation ---
      await _createAndSaveTranslatedPdf(
        translation.text,
        _selectedTargetLanguageCode,
      );

      setState(() {
        _isTranslating = false;
      });
    } catch (e) {
      print('Document Translation error: $e');
      setState(() {
        _documentStatus = "Error during translation.";
        _isTranslating = false;
      });
    }
  }

  // --- Function to Create and Save the Translated PDF (SIMPLIFIED) ---
  Future<void> _createAndSaveTranslatedPdf(
    String translatedText,
    String langCode,
  ) async {
    try {
      final pdf = pw.Document();

      // NOTE: Removed custom font loading to simplify. Non-Latin characters may not display correctly.

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  // CORRECTED: Using the helper function here
                  'Translated Document (${_getLanguageName(langCode)})',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                // Using basic default font styling
                pw.Text(
                  translatedText,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      );

      // Get the documents directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_sourceFileName}_translated_${langCode}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save the PDF file
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        setState(() {
          _documentStatus = 'Translation Complete! File saved to: ${file.path}';
        });

        // Open the file for the user to view (requires open_filex package)
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      print('PDF Creation/Save Error: $e');
      if (mounted) {
        setState(() {
          _documentStatus = 'Error saving the translated file.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 50),
          const Icon(Icons.description, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 20),

          // Source File Name Display
          if (_sourceFileName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                _sourceFileName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Status Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              _documentStatus,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Browse Button
          ElevatedButton(
            onPressed: _isProcessing || _isTranslating
                ? null
                : _pickDocumentFile,
            child: Text(
              _isProcessing ? 'Processing...' : 'Browse your computer',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              foregroundColor: Colors.black54,
              backgroundColor: Colors.grey.shade200,
            ),
          ),

          const SizedBox(height: 40),

          // Language Selector and Translate Button
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
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTargetLanguageCode = newValue;
                            // Re-run translation if text is already extracted
                            if (_extractedText.isNotEmpty &&
                                !_isProcessing &&
                                !_isTranslating) {
                              _translateExtractedText(_extractedText);
                            } else {
                              _documentStatus =
                                  'Target language set to ${_getLanguageName(newValue)}.';
                            }
                          });
                        }
                      },
                      items: _languages.entries.map<DropdownMenuItem<String>>((
                        MapEntry<String, String> entry,
                      ) {
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
              // Translate Button (Used only if language is changed)
              ElevatedButton.icon(
                onPressed:
                    (_isProcessing || _isTranslating || _extractedText.isEmpty)
                    ? null
                    : () {
                        _translateExtractedText(_extractedText);
                      },
                icon: _isTranslating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.translate),
                label: Text(_isTranslating ? 'Translating...' : 'Translate'),
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
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class WebsitesTabContent extends StatelessWidget {
  const WebsitesTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.language, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 20),
          const Text(
            'Translate an entire webpage.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.translate),
                onPressed: () {
                  // Implement website translation logic
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: 'en', // Default value
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'vi', child: Text('Vietnamese')),
            ],
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MyHomePage (Images tab: OCR, Translation, File Picker)
// =========================================================================

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

  // --- Language Selection Variables ---
  final Map<String, String> _languages = {
    'Vietnamese': 'vi',
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Japanese': 'ja',
  };

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

  // Function for System File Picker (restricted to images)
  Future<void> _pickFileFromSystem() async {
    final result = await FilePicker.platform.pickFiles(
      // CRITICAL: We restrict to image files for OCR functionality
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'tiff'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      await _processImage(pickedFile);
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
      _translatedText = "Translation"; // Reset translation
    });

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    textRecognizer.close();

    setState(() {
      _extractedText = recognizedText.text.isEmpty
          ? 'Could not recognize any text.'
          : recognizedText.text;
      print("OCR Raw Output: $_extractedText");
      _extractedText = _extractedText.replaceAll('\n', ' ');
      print("OCR Processed Output: $_extractedText");
      _isProcessing = false;
    });
  }

  // --- Translation Logic ---
  Future<void> _translateText(String extractedText) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Image Display
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

              // Button 1: Gallery
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Select from Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 15),

              // Button 2: Camera
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

              // NEW BUTTON: Upload File (System Picker for Images)
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickFileFromSystem,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Image File (System Picker)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 15),

              // Language Selector and Translate Button in a Row
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
                                _translatedText = "Translation target changed.";
                              });
                            }
                          },
                          items: _languages.entries
                              .map<DropdownMenuItem<String>>((
                                MapEntry<String, String> entry,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: entry.value,
                                  child: Text(
                                    'Translate to: ${entry.key}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              })
                              .toList(),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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

              const SizedBox(height: 40),

              // Extracted Text Display
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

              // Translated Text Display
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

              // ===== CHATBOT BUTTON =====
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
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

// =========================================================================
// CAMERA PREVIEW VIEW (Unchanged)
// =========================================================================

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
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (!context.mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      print('Error taking picture: $e');
      if (context.mounted) {
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
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
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
