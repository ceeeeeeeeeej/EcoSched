import 'dart:async';
import 'dart:typed_data';
import 'dart:ui'; // For ImageFilter

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Ensure this is available or use Text
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

  void _returnResultToCaller() {
    if (_capturedImageBytes == null || _lastReply == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Scan an item first so we can share the result.',
      );
      return;
    }
    Navigator.of(context).pop(
      LiveScanResult(imageBytes: _capturedImageBytes!, reply: _lastReply!),
    );
  }

  Future<void> _scanOnce() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isScanning) {
      return;
    }
    setState(() => _isScanning = true);
    try {
      final XFile file = await _controller!.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      
      setState(() {
        _capturedImageBytes = bytes;
        _lastReply = null;
        _showTips = false; // Hide tips when showing result
      });

      final String prompt = '''
You are EcoSched, a professional waste sorting expert.
Analyze the image and provide a structured response about the waste item.

Format your response exactly as follows using Markdown:
## Classification
[State clearly if it is Biodegradable, Non-Biodegradable (Recyclable), Non-Biodegradable (Residual), or Hazardous]

## Disposal Tip
[One practical, concise sentence on how to dispose of it properly in Tago]

## Key Fact
[A short, interesting benefit of disposing this item correctly]

If the image does not show waste or trash, reply with:
"**Not Waste detected.** Please scan a waste item."
''';
      
      final reply = await _chatService.sendMessageWithImages(
        prompt,
        [DataPart('image/jpeg', bytes)],
      );
      
      if (mounted) {
        setState(() {
          _lastReply = reply;
        });
        _showResultSheet();
      }
    } catch (e) {
      ErrorHandler.handleError(e, StackTrace.current, context: 'Live scan');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not analyze photo. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (context) => _GlassResultSheet(
        reply: _lastReply!,
        onUseResult: _returnResultToCaller,
        onScanAgain: () {
            Navigator.pop(context);
            setState(() {
                _capturedImageBytes = null;
                _lastReply = null;
            });
        },
      ),
    ).whenComplete(() {
        // If sheet is dismissed by dragging, we might want to reset or keep state
        // For now, let's keep the image but allow rescanning from the main button
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('EcoScan Live'),
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Preview or Captured Image
              if (_capturedImageBytes != null)
                Image.memory(_capturedImageBytes!, fit: BoxFit.cover)
              else
                CameraPreview(_controller!),

              // 2. Scanning Overlay (Dimmer)
              if (_isScanning)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryGreen),
                        const SizedBox(height: 20),
                        Text(
                          'Analyzing Waste...',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Tips Section (only when not scanning/showing result)
              if (_showTips && !_isScanning && _capturedImageBytes == null)
                Positioned(
                  bottom: 100, // Above the scan button
                  left: 16,
                  right: 16,
                  child: _GlassTipCard(
                    onClose: () => setState(() => _showTips = false),
                  ),
                ),
                
              // 4. Scan Button Area
              if (!_isScanning && _capturedImageBytes == null)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _scanOnce,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            size: 32, color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassTipCard extends StatelessWidget {
  final VoidCallback onClose;

  const _GlassTipCard({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan for Instant Tips',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Point at any waste item and tap the button. EcoSched will tell you if it\'s recyclable and how to dispose of it.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassResultSheet extends StatelessWidget {
  final String reply;
  final VoidCallback onUseResult;
  final VoidCallback onScanAgain;

  const _GlassResultSheet({
    required this.reply,
    required this.onUseResult,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.neutral900.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (reply.contains('Not Waste detected'))
                     _buildErrorContent(context)
                  else
                     _buildStructuredContent(context),
                  
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onScanAgain,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Scan Again'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!reply.contains('Not Waste detected'))
                      Expanded(
                          child: ElevatedButton(
                            onPressed: onUseResult,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Use Result'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline_rounded, size: 64, color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          'Not Waste Detected',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Please ensure you are scanning a waste or trash item specifically.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStructuredContent(BuildContext context) {
    // Basic Markdown parsing tailored for the prompt
    // We can just use the MarkdownBody widget for easy rich text
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            children: [
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Scan Successful',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                        ),
                    ),
                ),
            ],
        ),
        const SizedBox(height: 20),
        MarkdownBody(
          data: reply,
          styleSheet: MarkdownStyleSheet(
            h2: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 2.0,
            ),
            p: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
            ),
            strong: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
            ),
             blockSpacing: 12,
          ),
        ),
      ],
    );
  }
}
