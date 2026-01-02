import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '/theme/app_theme.dart';
import 'enter_amount_screen.dart';
import '/utils/eip681_parser.dart'; 

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  
  bool _isScanning = true;
  bool _isFlashOn = false; 
  double _zoomLevel = 0.0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final rawQr = barcode.rawValue!;
        // 1. Try to parse as EIP standard
        final parsedModel = Eip681Parser.parse(rawQr);
        
        // 2. Fallback: If not EIP, use raw string
        final cleanAddress = parsedModel?.toAddress ?? rawQr;
        // --------------------------------------

        setState(() {
          _isScanning = false;
        });
        
        // Navigate to Amount Screen with the CLEANED address
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnterAmountScreen(toAddress: cleanAddress),
          ),
        ).then((_) {
          // Resume scanning when returning
          setState(() {
            _isScanning = true;
          });
          controller.start();
        });
        break; 
      }
    }
  }

  void _toggleScanState() {
    if (_isScanning) {
      controller.stop();
      setState(() => _isScanning = false);
    } else {
      controller.start();
      setState(() => _isScanning = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: BlockPayTheme.electricGreen,
                borderRadius: 16,
                borderLength: 40,
                borderWidth: 6,
                cutOutSize: 280,
                overlayColor: BlockPayTheme.obsidianBlack.withOpacity(0.85),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBlurButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          _buildBlurButton(
                            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn ? BlockPayTheme.electricGreen : Colors.white,
                            onPressed: () async {
                              await controller.toggleTorch();
                              setState(() {
                                _isFlashOn = !_isFlashOn;
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildBlurButton(
                            icon: Icons.cameraswitch_outlined,
                            onPressed: () => controller.switchCamera(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isScanning ? 'Align QR code within the frame' : 'Scanning Paused',
                        style: BlockPayTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Icon(Icons.zoom_out, color: Colors.white54, size: 20),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: BlockPayTheme.electricGreen,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: BlockPayTheme.electricGreen.withOpacity(0.2),
                                trackHeight: 2,
                              ),
                              child: Slider(
                                value: _zoomLevel,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (value) {
                                  setState(() => _zoomLevel = value);
                                  controller.setZoomScale(value);
                                },
                              ),
                            ),
                          ),
                          const Icon(Icons.zoom_in, color: Colors.white54, size: 20),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: _toggleScanState,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isScanning 
                                ? Colors.white10 
                                : BlockPayTheme.electricGreen,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isScanning ? Colors.white24 : Colors.transparent
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isScanning ? Icons.pause : Icons.play_arrow,
                                color: _isScanning ? Colors.white : Colors.black,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isScanning ? 'Pause Scanner' : 'Resume Scanning',
                                style: TextStyle(
                                  color: _isScanning ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurButton({
    required IconData icon, 
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;
  final Color overlayColor;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderRadius = 10,
    this.borderLength = 40,
    this.borderWidth = 10,
    this.cutOutSize = 250,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: rect.center, width: cutOutSize, height: cutOutSize),
          Radius.circular(borderRadius)));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addPath(Path()..addRect(rect), Offset.zero)
      ..addPath(
        getInnerPath(rect, textDirection: textDirection), 
        Offset.zero
      )
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
      center: rect.center, 
      width: cutOutSize, 
      height: cutOutSize
    );

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}