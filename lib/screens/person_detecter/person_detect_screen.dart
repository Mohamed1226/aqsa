import 'package:aqsa/common/core/utilities/scanner.dart';
import 'package:aqsa/screens/person_detecter/widgets/face_painter_widget.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class PersonDetectorScreen extends StatefulWidget {
  const PersonDetectorScreen({super.key});

  @override
  State<PersonDetectorScreen> createState() => _PersonDetectorScreenState();
}

class _PersonDetectorScreenState extends State<PersonDetectorScreen> {
  bool isWorking = false;
  CameraController? cameraController;
  FaceDetector? faceDetector;
  Size? size;
  List<Face>? faces;
  CameraDescription? cameraDescription;
  CameraLensDirection cameraLensDirection = CameraLensDirection.front;

  @override
  initState() {
    initCamera();
    super.initState();
  }

  initCamera() async {
    cameraDescription = await Scanner.getCamera(cameraLensDirection);
    cameraController =
        CameraController(cameraDescription!, ResolutionPreset.medium);

    faceDetector = FaceDetector(
        options: FaceDetectorOptions(
            enableClassification: true,
            minFaceSize: 0.1,
            performanceMode: FaceDetectorMode.fast));

    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      cameraController!.startImageStream((image) {
        if (!isWorking) {
          isWorking = true;
        }
        performDetection(image);
      });
    });
  }

  performDetection(CameraImage image) {
    Scanner.detect(
            image: image,
            // detectImage: faceDetector!.processImage,
            rotation: cameraDescription!.sensorOrientation)
        .then((value) {
      faces = value;
    }).whenComplete(() {
      setState(() {
        isWorking = false;
      });
    });
  }

  Widget buildResult() {
    if (faces == null ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return const Text('no result');
    }
    final size = Size(cameraController!.value.previewSize!.width,
        cameraController!.value.previewSize!.height);

    CustomPainter customPaint = FaceDetectPainter(size, faces!);
    return CustomPaint(
      painter: customPaint,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    final size = MediaQuery.of(context).size;
    if (cameraController != null) {
      children.add(Positioned(
          top: 0,
          left: 0,
          width: size.width,
          height: size.height - 250,
          child: (cameraController!.value.isInitialized)
              ? AspectRatio(
                  aspectRatio: cameraController!.value.aspectRatio,
                  child: CameraPreview(cameraController!),
                )
              : Container()));
    }

    children.add(Positioned(
        top: 0,
        left: 0,
        width: size.width,
        height: size.height - 250,
        child: buildResult()));

    return Scaffold(
      body: Container(
        child: Stack(
          children: children,
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController!.dispose();
    super.dispose();
  }
}
