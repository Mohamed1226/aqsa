import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ImagePicker? imagePicker;
  File? image;
  Interpreter? _interpreter;
  List<String>? _labels;

  @override
  initState() {
    imagePicker = ImagePicker();
    loadDataModel();
    super.initState();
  }

  Future<void> selectPhotoFromGallery() async {
    XFile? imagePicked =
        await imagePicker!.pickImage(source: ImageSource.gallery);
    if (imagePicked != null) {
      image = File(imagePicked.path);

      await classifyImage(image!);
      setState(() {});
    }
  }

  Future<void> selectPhotoFromCamera() async {
    XFile? imagePicked =
        await imagePicker!.pickImage(source: ImageSource.camera);
    if (imagePicked != null) {
      image = File(imagePicked.path);
      await classifyImage(image!);
      setState(() {});
    }
  }

  Future<void> loadDataModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');

    final labelData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelData.split('\n');
    log("interpreter $_interpreter $_labels");
  }








  Future<void> classifyImage(File image) async {
    // Load the image
    img.Image? originalImage = img.decodeImage(image.readAsBytesSync());
    if (originalImage == null) {
      print('Error: Could not decode image.');
      return;
    }

    // Resize the image to 224x224
    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

    // Convert the resized image to a byte array (RGB format)
    int totalPixels = 224 * 224;
    Uint8List imageBytes = Uint8List(totalPixels * 3);
    for (int i = 0; i < totalPixels; i++) {
      int pixel = resizedImage[i];
      imageBytes[i * 3] = img.getRed(pixel);
      imageBytes[i * 3 + 1] = img.getGreen(pixel);
      imageBytes[i * 3 + 2] = img.getBlue(pixel);
    }

    // Reshape the byte array to match the input shape of the model
    var input = [[1.23, 6.54, 7.81, 3.21, 2.22]];

    // Prepare output tensor
    var output = List.generate(1, (_) => List.filled(_labels!.length, 0));

    _interpreter!.run(input, output);

    // Process the output to find the highest probability
    var highestProb = 0.0;
    var labelIndex = 0;
    for (var i = 0; i < _labels!.length; i++) {
      if (output[0][i] > highestProb) {
        highestProb = output[0][i].toDouble();
        labelIndex = i;
      }
    }

    // Log the prediction
    print('Prediction: ${_labels![labelIndex]}, Confidence: $highestProb');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: () {
                        selectPhotoFromCamera();
                      },
                      child: Text("From Camera")),
                  TextButton(
                      onPressed: () {
                        selectPhotoFromGallery();
                      },
                      child: Text("From Gallery")),
                ],
              ),
            ),
            if (image != null)
              Image.file(
                image!,
                height: 400,
                width: 300,
              ),
          ],
        ),
      ),
    );
  }
}
