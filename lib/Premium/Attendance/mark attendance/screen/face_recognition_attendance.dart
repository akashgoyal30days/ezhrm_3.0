import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  late Interpreter _faceNetInterpreter;
  late List<int> _faceNetInputShape;
  late List<int> _faceNetOutputShape;

  bool _isLoaded = false;

  Future<void> loadModel() async {
    try {
      print("Starting model loading process...");
      final options = InterpreterOptions()..addDelegate(GpuDelegateV2());
      print(
          "Attempting to load model from asset: 'assets/modals/mobile_face_net.tflite'");
      _faceNetInterpreter = await Interpreter.fromAsset(
          'assets/modals/mobile_face_net.tflite',
          options: options);

      _faceNetInputShape = _faceNetInterpreter.getInputTensor(0).shape;
      _faceNetOutputShape = _faceNetInterpreter.getOutputTensor(0).shape;

      _isLoaded = true;
      print(
          "Model loaded successfully. Input shape: $_faceNetInputShape, Output shape: $_faceNetOutputShape");
    } catch (e) {
      print("Error loading model: $e");
      _isLoaded = false;
    }
  }

  bool get isModelLoaded => _isLoaded;

  Float32List preprocessFace(img.Image image) {
    if (!_isLoaded) {
      print("Error: Model not loaded yet. Cannot preprocess face.");
      throw Exception("Model not loaded yet");
    }

    print("Preprocessing image of size: ${image.width}x${image.height}");
    final resizedImage = img.copyResize(image,
        width: _faceNetInputShape[1], height: _faceNetInputShape[2]);
    print(
        "Image resized to input shape dimensions: ${resizedImage.width}x${resizedImage.height}");

    final imageMatrix = Float32List(1 *
        _faceNetInputShape[1] *
        _faceNetInputShape[2] *
        _faceNetInputShape[3]);
    final pixels = resizedImage.getBytes();

    for (int i = 0; i < pixels.length; i += 3) {
      final int r = pixels[i];
      final int g = pixels[i + 1];
      final int b = pixels[i + 2];

      imageMatrix[i] = (r - 127.5) / 127.5;
      imageMatrix[i + 1] = (g - 127.5) / 127.5;
      imageMatrix[i + 2] = (b - 127.5) / 127.5;
    }

    print("Image preprocessing complete. Normalization applied.");
    return imageMatrix;
  }

  List<double> getFaceEmbedding(img.Image faceImage) {
    if (!_isLoaded) {
      print("Error: Model not loaded yet. Cannot get face embedding.");
      throw Exception("Model not loaded yet");
    }

    print("Starting face embedding process...");
    final preprocessedFace = preprocessFace(faceImage);
    final input = preprocessedFace.reshape(_faceNetInputShape);

    print("Running model inference...");
    final output =
        List.filled(_faceNetOutputShape[0] * _faceNetOutputShape[1], 0.0)
            .reshape(_faceNetOutputShape);

    _faceNetInterpreter.run(input, output);

    print("Inference complete. Output shape: ${output[0].length}");
    return output[0].cast<double>();
  }
}
