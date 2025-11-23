import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/services/ai_chat_service.dart';
import '../core/error/error_handler.dart';
import '../core/theme/app_theme.dart';

class LiveScanResult {
  final Uint8List imageBytes;
  final String reply;
  LiveScanResult({required this.imageBytes, required this.reply});
}

class LiveScanScreen extends StatefulWidget {
  final String apiKey;
  const LiveScanScreen({super.key, required this.apiKey});

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _isScanning = false;
  String? _lastReply;
  Uint8List? _capturedImageBytes;
  late final AiChatService _chatService;
  bool _showTips = true;

  @override
  void initState() {
    super.initState();
    _chatService = AiChatService(widget.apiKey);
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final PermissionStatus cam = await Permission.camera.request();
      if (!cam.isGranted) {
        throw Exception('Camera permission denied');
      }
      final List<CameraDescription> cameras = await availableCameras();
      final CameraDescription camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller =
          CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      ErrorHandler.handleError(e, StackTrace.current, context: 'Init camera');
    }
  }

  Future<void> _scanOnce() async {
    if (_controller == null || !_controller!.value.isInitialized || _isScanning) {
      return;
    }
    setState(() => _isScanning = true);
    try {
      final XFile file = await _controller!.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        // Show the captured photo in the center while we analyze it
        _capturedImageBytes = bytes;
        _lastReply = null;
      });
      final String prompt = '''
You are EcoSched, a friendly waste sorting assistant for Tago, Surigao del Sur.

1. First, decide if the main object in the photo is a piece of WASTE or TRASH (like packaging, bottles, cans, food scraps, paper, or plastic).
2. If it is NOT clearly waste/trash (for example a person, pet, scenery, or an everyday object), politely say that this doesn't look like trash and kindly ask the user to scan a waste item instead.
3. If it IS waste/trash, clearly classify it as one of:
   - biodegradable
   - non-biodegradable (recyclable)
   - non-biodegradable (not recyclable)
   - hazardous
4. Give a short, practical disposal tip that makes sense for a household in Tago.

Reply in 1–3 friendly sentences, speaking directly to the user.
''';
      final reply = await _chatService.sendMessageWithImages(
        prompt,
        [DataPart('image/jpeg', bytes)],
      );
      if (mounted) {
        setState(() {
          _lastReply = reply;
        });
      }
    } catch (e) {
      ErrorHandler.handleError(e, StackTrace.current, context: 'Live scan');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoScan Live'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.textInverse,
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _capturedImageBytes != null
                          ? Container(
                              color: Colors.black,
                              alignment: Alignment.center,
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _capturedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          : CameraPreview(_controller!),
                    ),
                    if (_isScanning)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Analyzing your photo…',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_lastReply != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lastReply!,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed:
                                      _isScanning ? null : () => _scanOnce(),
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Scan again',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_showTips) _buildHistorySection(context),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _isScanning ? null : _scanOnce,
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(_isScanning ? 'Scanning…' : 'Scan my trash'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'How EcoScan Live helps you',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showTips = false;
                  });
                },
                tooltip: 'Hide tips',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Point at a waste item like a bottle, wrapper, or food scrap.\n'
            '• Tap "Scan my trash" and wait a moment.\n'
            '• Get a simple explanation and disposal tip for your household.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
