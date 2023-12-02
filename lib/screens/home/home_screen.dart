import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ImagePicker? imagePicker;
  File? image;
  String? _label;

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
    String? res = await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: 'assets/labels.txt',
        numThreads: 1,
        // defaults to 1
        isAsset: true,
        // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );
  }

  Future<void> classifyImage(File image) async {
    var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        // required
        imageMean: 0.0,
        // defaults to 117.0
        imageStd: 255.0,
        // defaults to 1.0
        numResults: 2,
        // defaults to 5
        threshold: 0.2,
        // defaults to 0.1
        asynch: true // defaults to true
        );
    _label = recognitions?.first["label"];
    log("recognitions $recognitions");
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
            if (_label != null) Text(_label!)
          ],
        ),
      ),
    );
  }
}
