import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class FaceDetectionService {
  late FaceDetector _faceDetector;

  FaceDetectionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true, // Essential for liveness (eyes/smile)
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15, // Detect faces even if slightly far
      ),
    );
  }

  Future<List<Face>> detectFaces(CameraImage image, int sensorOrientation) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageMetadata,
    );

    return await _faceDetector.processImage(inputImage);
  }

  /// Determines if the user has performed a "Blink" based on probability history.
  /// Returns true if a blink is completed (Eyes Open -> Closed -> Open).
  bool checkForBlink(Face face, bool eyesWerePreviouslyClosed) {
    final double? leftEye = face.leftEyeOpenProbability;
    final double? rightEye = face.rightEyeOpenProbability;

    if (leftEye == null || rightEye == null) return false;

    // Thresholds
    const double openThreshold = 0.85;
    const double closedThreshold = 0.15;

    bool areEyesClosed = (leftEye < closedThreshold) && (rightEye < closedThreshold);
    bool areEyesOpen = (leftEye > openThreshold) && (rightEye > openThreshold);

    // State Machine logic handled by caller usually, but helper here:
    // If eyes are now OPEN, but were previously CLOSED, that's a blink complete.
    if (areEyesOpen && eyesWerePreviouslyClosed) {
      return true;
    }
    
    return false;
  }
  
  // Helper to update state
  bool areEyesClosed(Face face) {
     final double? leftEye = face.leftEyeOpenProbability;
    final double? rightEye = face.rightEyeOpenProbability;
    if (leftEye == null || rightEye == null) return false;
    return (leftEye < 0.15) && (rightEye < 0.15);
  }

  void dispose() {
    _faceDetector.close();
  }
}