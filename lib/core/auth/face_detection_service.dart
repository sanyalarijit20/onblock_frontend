import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class FaceDetectionService {
  late FaceDetector _faceDetector;
  
  // Liveness detection tracking
  bool _eyesWerePreviouslyClosed = false;
  int _blinkCount = 0;
  DateTime? _lastBlinkTime;
  double? _previousHeadTurnX;

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

  /// Checks if eyes are currently closed based on probability thresholds.
  bool _areEyesClosed(Face face) {
    final double? leftEye = face.leftEyeOpenProbability;
    final double? rightEye = face.rightEyeOpenProbability;
    
    if (leftEye == null || rightEye == null) return false;
    
    // Both eyes must have low probability to be considered closed
    const double closedThreshold = 0.15;
    return (leftEye < closedThreshold) && (rightEye < closedThreshold);
  }

  /// Checks if eyes are currently open based on probability thresholds.
  bool _areEyesOpen(Face face) {
    final double? leftEye = face.leftEyeOpenProbability;
    final double? rightEye = face.rightEyeOpenProbability;
    
    if (leftEye == null || rightEye == null) return false;
    
    // Both eyes must have high probability to be considered open
    const double openThreshold = 0.85;
    return (leftEye > openThreshold) && (rightEye > openThreshold);
  }

  bool _detectBlink(Face face) {
    final bool currentlyClosed = _areEyesClosed(face);
    final bool currentlyOpen = _areEyesOpen(face);

    // Transition detected: Eyes were closed, now they're open = blink completed
    if (_eyesWerePreviouslyClosed && currentlyOpen) {
      _eyesWerePreviouslyClosed = false;
      _lastBlinkTime = DateTime.now();
      return true;
    }

    // Update state: Track if eyes are currently closed
    if (currentlyClosed) {
      _eyesWerePreviouslyClosed = true;
    } else if (currentlyOpen) {
      _eyesWerePreviouslyClosed = false;
    }

    return false;
  }

  /// Detects head movement (yaw angle) for liveness.
  /// Returns true if significant head turn is detected (left/right movement).
  bool _detectHeadTurn(Face face) {
    final double? headTurnX = face.headEulerAngleY; // Yaw (left/right turn)
    
    if (headTurnX == null) return false;

    // Initialize on first detection
    if (_previousHeadTurnX == null) {
      _previousHeadTurnX = headTurnX;
      return false;
    }

    // Detect if head has turned significantly (threshold in degrees)
    const double turnThreshold = 15.0; // 15 degree turn threshold
    final double headMovement = (headTurnX - (_previousHeadTurnX ?? 0)).abs();

    _previousHeadTurnX = headTurnX;

    return headMovement > turnThreshold;
  }

  bool checkLiveness(Face face) {
    // Must detect a blink as primary liveness indicator
    final bool blinkDetected = _detectBlink(face);
    
    if (blinkDetected) {
      _blinkCount++;
    }

 
    final bool headMovementDetected = _detectHeadTurn(face);
    return _blinkCount >= 1;
  }

  /// Get current blink count for UI feedback.
  int getBlinkCount() => _blinkCount;

  /// Reset liveness detection state (call this at the start of a new liveness check).
  void resetLivenessState() {
    _eyesWerePreviouslyClosed = false;
    _blinkCount = 0;
    _lastBlinkTime = null;
    _previousHeadTurnX = null;
  }
  bool hasRecentBlink(int seconds) {
    if (_lastBlinkTime == null) return false;
    final difference = DateTime.now().difference(_lastBlinkTime!);
    return difference.inSeconds < seconds;
  }

  void dispose() {
    _faceDetector.close();
  }
}