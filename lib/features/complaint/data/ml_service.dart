import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/sorted_unsorted_model.tflite',
    );
  }

  Future<double> predict(File imageFile) async {
    final rawImage = img.decodeImage(await imageFile.readAsBytes());
    final resizedImage = img.copyResize(rawImage!, width: 224, height: 224);

    // This creates the empty 4D list (shape: [1, 224, 224, 3])
    var input = List.generate(
      1,
          (_) => List.generate(
        224,
            (y) => List.generate(
          224,
              (x) => List.filled(3, 0.0),
        ),
      ),
    );

    // --- LOOP STARTS HERE ---
    // We loop through every row (y) and every pixel in that row (x)
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        // Get the pixel at the specific X and Y coordinate
        final pixel = resizedImage.getPixel(x, y);

        // Normalize the Red, Green, and Blue values (0-255) to (0.0-1.0)
        // We use .r, .g, and .b because of the package update
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }
    // --- LOOP ENDS HERE ---

    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    _interpreter.run(input, output);

    return output[0][0];
  }
}
