import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../gemini_service.dart';
import '../firebase_operations.dart';
import '../util.dart';

class ImageAnalyzer extends StatefulWidget {
  final String analysisType; // 'pad' or 'food'
  final GeminiService geminiService;

  const ImageAnalyzer({
    super.key,
    required this.analysisType,
    required this.geminiService,
  });

  @override
  State<ImageAnalyzer> createState() => _ImageAnalyzerState();
}

class _ImageAnalyzerState extends State<ImageAnalyzer> {
  final ImagePicker _picker = ImagePicker();
  
  Uint8List? _imageBytes;
  String? _analysis;
  bool _isLoading = false;

  Future<void> _pickImage() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );

  if (image == null) return;

  if (!mounted) return;
  setState(() {
    _isLoading = true;
    _analysis = null;
  });

  try {
    final bytes = await image.readAsBytes();

    final String today = getCurrentLocalDate();
    final String? phase = await getCurrentPhase(today);

    final String result;
    if (widget.analysisType == 'pad') {
      result = await widget.geminiService.analyzePadImage(bytes, phase ?? 'period');
    } else {
      result = await widget.geminiService.analyzeFoodImage(bytes, phase ?? 'period');
    }

    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _analysis = result;
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.contain,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_analysis != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Text(
                _analysis!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(
                _imageBytes == null 
                  ? 'Take Photo' 
                  : 'Take Another Photo',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}