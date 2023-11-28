import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter/tflite_flutter.dart';

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
    var imageBytes = (img.decodeImage(image.readAsBytesSync()))!;
    img.Image resizedImage =
        img.copyResize(imageBytes, width: 224, height: 224);
    Uint8List imageAsList = resizedImage.getBytes();
    var input = imageAsList.buffer.asUint32List().reshape([1, 224, 224, 3]);

    // Prepare output tensor
    var output = List.generate(1, (_) => List.filled(_labels!.length, 0));

    _interpreter!.run(input, output);

    var highestProb = 0.0;
    var labelIndex = 0;
    for (var i = 0; i < _labels!.length; i++) {
      if (output[0][i] > highestProb) {
        highestProb = output[0][i].toDouble();
        labelIndex = i;
      }
    }

    log('Prediction: ${_labels![labelIndex]}, Confidence: $highestProb');
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
