import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'lib\features\complaint\data\ml_service.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final TextEditingController _detailsController = TextEditingController();
  String? _prediction;
  double? _confidence;
  bool _isLoading = false;
  bool _isAnalyzed = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  // Helper to shrink image size before uploading to the cloud
  Future<XFile?> _compressImage(String path) async {
    final targetPath = p.join(p.dirname(path), "compressed_${p.basename(path)}");

    return await FlutterImageCompress.compressAndGetFile(
      path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );
  }

  // Runs the TFLite model on the captured image
  Future<void> _runModel(String imagePath) async {
    setState(() {
      _isLoading = true;
      _prediction = null;
    });

    try {
      final ml = MLService();
      await ml.loadModel();
      final double rawValue = await ml.predict(File(imagePath));

      String label;
      double certainty;

      // Logic: Index 0 is Sorted, 1 is Unsorted (verify with your labels.txt)
      if (rawValue > 0.5) {
        label = "Unsorted";
        certainty = rawValue;
      } else {
        label = "Sorted";
        certainty = 1.0 - rawValue;
      }

      // Certainty threshold to catch "Out-of-Distribution" images (like your laptop)
      const double threshold = 0.75;

      setState(() {
        if (certainty < threshold) {
          _prediction = "Invalid / Unclear Image";
          _confidence = certainty;
          _isAnalyzed = false;
        } else {
          _prediction = label;
          _confidence = certainty;
          _isAnalyzed = true;
        }
      });
    } catch (e) {
      debugPrint("Model Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sends the image and metadata to your Node.js backend
  Future<void> _submitComplaint() async {
    setState(() => _isLoading = true);

    try {
      final compressedFile = await _compressImage(widget.imagePath);
      if (compressedFile == null) throw Exception("Compression failed");

      // Replace with your live API URL once deployed
      var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.32.226.164:3000/complaints')
      );

      request.fields['prediction'] = _prediction!;
      request.fields['confidence'] = _confidence!.toStringAsFixed(4);
      request.fields['description'] = _detailsController.text;
      request.fields['status'] = 'Pending';
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      request.files.add(
          await http.MultipartFile.fromPath('image', compressedFile.path)
      );

      var response = await request.send();

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Submission Successful"),
        content: const Text("Your complaint and AI analysis have been sent to the authorities."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complaint Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Dynamic Image Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                height: _isAnalyzed ? 200 : 400,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            if (_isLoading) const CircularProgressIndicator(),

            // 2. Out-of-Distribution / Error UI
            if (_prediction == "Invalid / Unclear Image")
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                    const Text(
                      "Image Not Recognized",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Text("AI is unsure. Ensure the waste is visible and try again.", textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("GO BACK TO CAMERA"),
                    ),
                  ],
                ),
              ),

            // 3. Analysis Results & Submission Form
            if (_isAnalyzed) ...[
              Card(
                elevation: 0,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResultColumn("Result", _prediction!,
                              _prediction == "Sorted" ? Colors.green : Colors.red),
                          _buildResultColumn("Confidence",
                              "${(_confidence! * 100).toStringAsFixed(1)}%", Colors.black),
                        ],
                      ),
                      const Divider(height: 30),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _prediction = (_prediction == "Sorted") ? "Unsorted" : "Sorted";
                          });
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Not correct? Change result"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Explain your complaint",
                  hintText: "e.g. Garbage missed for 3 days...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitComplaint,
                  child: const Text("SUBMIT COMPLAINT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            // 4. Initial Control Buttons
            if (!_isAnalyzed && !_isLoading && _prediction != "Invalid / Unclear Image")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retake"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _runModel(widget.imagePath),
                    icon: const Icon(Icons.analytics),
                    label: const Text("Analyze & Confirm"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}