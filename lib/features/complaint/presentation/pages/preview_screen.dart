import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:cleansl_complaint_module/features/complaint/data/ml_service.dart';

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
    final targetPath = p.join(
      p.dirname(path),
      "compressed_${p.basename(path)}",
    );

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

      final result = await ml.predict(File(imagePath));

      String label = result["label"];
      double confidence = result["confidence"];

      const double threshold = 0.6; // adjust if needed

      setState(() {
        if (confidence < threshold) {
          _prediction = "Unsorted (Mixed / Unclear)";
          _confidence = confidence;
          _isAnalyzed = true;
        } else {
          _prediction = label.toUpperCase();
          _confidence = confidence;
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
        Uri.parse('https://cleansl-backend-supabase.onrender.com/complaints'),
      );

      request.fields['prediction'] = _prediction!;
      request.fields['confidence'] = _confidence!.toStringAsFixed(4);
      request.fields['description'] = _detailsController.text;
      request.fields['status'] = 'Pending';
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      request.files.add(
        await http.MultipartFile.fromPath('image', compressedFile.path),
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
        SnackBar(
          content: Text("Failed to send: $e"),
          backgroundColor: Colors.red,
        ),
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
        content: const Text(
          "Your complaint and AI analysis have been sent to the authorities.",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Complaint Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Dynamic Image Preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF26D15B).withOpacity(0.05),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(widget.imagePath),
                  height: _isAnalyzed ? 240 : 450,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const CircularProgressIndicator(color: Color(0xFF26D15B)),

            // 2. Out-of-Distribution / Error UI
            if (_prediction == "Unsorted (Mixed / Unclear)")
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade700, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade400,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Image Not Recognized",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "AI is unsure. Ensure the waste is visible and try again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange.shade300,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "GO BACK TO CAMERA",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Analysis Results & Submission Form
            if (_isAnalyzed && _prediction != "Unsorted (Mixed / Unclear)") ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF102616),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1A3A22),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultColumn(
                        "Material",
                        _prediction!,
                        [
                              "PLASTIC",
                              "GLASS",
                              "METAL",
                              "PAPER",
                              "ORGANIC",
                            ].contains(_prediction)
                            ? const Color(0xFF26D15B)
                            : Colors.redAccent,
                      ),
                      if (_confidence != null)
                        _buildResultColumn(
                          "Confidence",
                          "${(_confidence! * 100).toStringAsFixed(1)}%",
                          const Color(0xFF4BA3E3),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Explain your complaint",
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  hintText: "e.g. Garbage missed for 3 days...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFF151E18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF28362B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF28362B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF26D15B)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26D15B),
                    foregroundColor: const Color(0xFF0B1C11),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _submitComplaint,
                  child: const Text(
                    "SUBMIT COMPLAINT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],

            // 4. Initial Control Buttons
            if (!_isAnalyzed &&
                !_isLoading &&
                _prediction != "Unsorted (Mixed / Unclear)")
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFF28362B),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text("Retake"),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26D15B),
                            foregroundColor: const Color(0xFF0B1C11),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _runModel(widget.imagePath),
                          icon: const Icon(Icons.analytics, size: 20),
                          label: const Text(
                            "Analyze Image",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
