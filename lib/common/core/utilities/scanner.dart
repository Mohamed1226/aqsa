import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class Scanner {
  const Scanner._();

  static Future<CameraDescription> getCamera(CameraLensDirection cameraLensDirection) async {
    return await availableCameras().then(
            (List<CameraDescription> cameras) => cameras.firstWhere(
                (CameraDescription description) => description.lensDirection == cameraLensDirection));
  }

  static InputImageRotation imageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      default:
        assert(rotation == 270);
        return InputImageRotation.rotation270deg;
    }
  }

  static InputImageFormat inputImageFormat(int format) {
    switch (format) {
      case 17: // ImageFormat.YUV_420_888
        return InputImageFormat.yuv_420_888;
      case 35: // ImageFormat.YUV_420_888 (Android)
        return InputImageFormat.yuv_420_888;
      default:
        throw Exception('Image format not supported');
    }
  }

  static InputImageMetadata buildMetaData(CameraImage image, InputImageRotation rotation) {
    return InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: inputImageFormat(image.format.raw),
      bytesPerRow: 1
    );
  }

  static Future<List<Face>> detect(
      {required CameraImage image,
        required int rotation}) async {
    final inputImage = InputImage.fromBytes(
      bytes: concatenatePlanes(image.planes),
      metadata: buildMetaData(image, imageRotation(rotation)),
    );

    final faceDetector = GoogleMlKit.vision.faceDetector();
    final List<Face> faces = await faceDetector.processImage(inputImage);
    faceDetector.close();

    return faces;
  }

  static concatenatePlanes(List<Plane> planes) {
    WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}
