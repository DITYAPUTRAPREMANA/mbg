import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../history/scan_history_repository.dart';

import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/model_service.dart';
import 'scan_detail_screen.dart';
import 'scan_models.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final int _selectedIndex = 1;
  final bool _scanSuccessful = false;

  late CameraController _cameraController;
  Future<void>? _initializeCameraFuture;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  final ModelService _modelService = ModelService(); // Instantiate the service

  @override
  void initState() {
    super.initState();
    _initializeCameraFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  void _toggleFlash() async {
    if (!_isCameraInitialized) return;
    try {
      if (_isFlashOn) {
        await _cameraController.setFlashMode(FlashMode.off);
      } else {
        await _cameraController.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _analyzeAndNavigate(File imageFile) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu")),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final resultData = await _modelService.analyzeFoodImage(
        imageFile: imageFile,
        userId: user.id,
      );

      if (mounted) {
        final scanResult = ScanResult.fromJson(resultData, imageFile.path);
        ScanHistoryRepository.instance.addResult(scanResult);

        print("Data dari Model: ${resultData.toString()}");
        print("Jumlah Ingredient: ${scanResult.ingredients.length}");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanDetailScreen(result: scanResult),
          ),
        );
      }
    } catch (e) {
      print("Error scan: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menganalisis: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _captureAndShowResult() async {
    if (!_isCameraInitialized || _isCapturing) return;
    try {
      final picture = await _cameraController.takePicture();
      await _analyzeAndNavigate(File(picture.path));
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isCapturing) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _analyzeAndNavigate(File(pickedFile.path));
    }
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }

    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Text(
                    'Scan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: Container(color: Colors.black)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(height: 10),
                        _buildScannerFrame(),
                        if (_scanSuccessful) _buildAnalysisCard(),
                        _buildActionRow(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  if (_isCapturing) _buildCaptureLoadingOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(child: _buildNavItem(Icons.dashboard, 'Dashboard', 0)),
            Flexible(
              child: _buildNavItem(Icons.camera_alt_outlined, 'Scan', 1),
            ),
            Flexible(child: _buildNavItem(Icons.history, 'History', 2)),
            Flexible(child: _buildNavItem(Icons.person_outline, 'Profile', 3)),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerFrame() {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: _initializeCameraFuture == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : FutureBuilder<void>(
                future: _initializeCameraFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      _isCameraInitialized) {
                    // Camera initialized - show preview
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CameraPreview(_cameraController),
                        ),
                        _buildFrameCorner(top: true, left: true),
                        _buildFrameCorner(top: true, left: false),
                        _buildFrameCorner(top: false, left: true),
                        _buildFrameCorner(top: false, left: false),
                        if (_scanSuccessful)
                          Positioned(
                            top: 18,
                            left: 20,
                            right: 20,
                            child: _buildScanLabel('Salmon', '85%'),
                          ),
                        if (_scanSuccessful)
                          Positioned(
                            bottom: 18,
                            left: 20,
                            right: 20,
                            child: _buildScanLabel('Avocado', '92%'),
                          ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    // Error initializing camera
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: Colors.black54,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white54,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Camera Error',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildFrameCorner(top: true, left: true),
                        _buildFrameCorner(top: true, left: false),
                        _buildFrameCorner(top: false, left: true),
                        _buildFrameCorner(top: false, left: false),
                      ],
                    );
                  } else {
                    // Loading camera
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.18),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        _buildFrameCorner(top: true, left: true),
                        _buildFrameCorner(top: true, left: false),
                        _buildFrameCorner(top: false, left: true),
                        _buildFrameCorner(top: false, left: false),
                      ],
                    );
                  }
                },
              ),
      ),
    );
  }

  Widget _buildFrameCorner({required bool top, required bool left}) {
    return Positioned(
      top: top ? 20 : null,
      bottom: top ? null : 20,
      left: left ? 20 : null,
      right: left ? null : 20,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: top
                ? BorderSide.none
                : const BorderSide(color: Colors.white, width: 3),
            right: left
                ? BorderSide.none
                : const BorderSide(color: Colors.white, width: 3),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildScanLabel(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4AB8FF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            '$title ($value)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7DD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.emoji_food_beverage,
                  color: Color(0xFF146620),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'ESTIMATED ANALYSIS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF66756A),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalysisStat('Calories', '420', const Color(0xFF146620)),
              _buildAnalysisStat('Protein', '28g', const Color(0xFF146620)),
              _buildAnalysisStat('Carbs', '12g', const Color(0xFF146620)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF97A38F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          Icons.photo_library,
          backgroundColor: Colors.white,
          onTap: _pickImageFromGallery,
        ),
        _buildActionButton(
          null,
          backgroundColor: const Color(0xFFFF8C00),
          size: 88,
          onTap: _captureAndShowResult,
        ),
        _buildActionButton(
          Icons.flash_on,
          backgroundColor: _isFlashOn ? const Color(0xFFFFD700) : Colors.white,
          iconColor: _isFlashOn ? Colors.orange : const Color(0xFF121E18),
          onTap: _toggleFlash,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData? icon, {
    Color backgroundColor = const Color(0xFFFFFFFF),
    Color iconColor = const Color(0xFF121E18),
    double size = 64,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: icon == null
            ? const SizedBox.shrink()
            : Icon(icon, color: iconColor, size: size * 0.4),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected
                ? const Color(0xFF146620)
                : const Color(0xFF97A38F),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF146620)
                  : const Color(0xFF97A38F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF146620)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Analyzing your meal...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121E18),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we process the image',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF66756A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
