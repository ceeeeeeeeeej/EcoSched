import 'dart:async';
import 'dart:typed_data';
import 'dart:ui'; // For ImageFilter

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Ensure this is available or use Text
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../core/services/ai_chat_service.dart';
import '../core/services/classification_service.dart';
import '../core/services/external_ai_service.dart';
import '../core/services/scan_service.dart';
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
  late final ClassificationService _classificationService;
  late final ExternalAiService _externalAiService;
  late final ScanService _scanService;
  bool _showTips = true;
  
  // Internal scan mode (Default to 1: External API)
  final int _scanMode = 1; 
  
  final ValueNotifier<bool> _isSaving = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _chatService = AiChatService(widget.apiKey);
    _classificationService = ClassificationService();
    _classificationService.loadModel();
    _externalAiService = ExternalAiService();
    _scanService = context.read<ScanService>();
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
          CameraController(camera, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      ErrorHandler.handleError(e, StackTrace.current, context: 'Init camera');
    }
  }

  Future<void> _returnResultToCaller() async {
    if (_capturedImageBytes == null || _lastReply == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Scan an item first so we can share the result.',
      );
      return;
    }

    _isSaving.value = true;
    
    try {
      if (kDebugMode) print('☁️ [Database] Uploading image to Supabase...');
      
      // 1. Upload the image bytes to storage
      final imageUrl = await _scanService.uploadScanImage(_capturedImageBytes!);
      
      if (imageUrl != null) {
        if (kDebugMode) print('☁️ [Database] Saving record: $imageUrl');
        
        // Extract label from reply (heuristic)
        String label = 'Unrecognized';
        if (_lastReply!.contains('## Classification')) {
          final lines = _lastReply!.split('\n');
          final classLine = lines.firstWhere((l) => l.contains('Classification'), orElse: () => '');
          if (classLine.isNotEmpty) {
            final nextLineIdx = lines.indexOf(classLine) + 1;
            if (nextLineIdx < lines.length) {
              label = lines[nextLineIdx].replaceAll('(Custom ML Model)', '').replaceAll('(Local Fallback)', '').trim();
            }
          }
        }

        // 2. Save the database record
        await _scanService.saveScanRecord(
          imageUrl: imageUrl, 
          label: label, 
          confidence: _scanMode == 0 ? 0.99 : 0.84, // Heuristic confidence
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Result saved to history!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ [Database] Failed to save result: $e');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Failed'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        _isSaving.value = false;
      }
    }
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
      
      // --- Pause camera to prevent CameraX LiveData crash during long API wait ---
      try { await _controller?.pausePreview(); } catch (_) {}
      
      setState(() {
        _capturedImageBytes = bytes;
        _lastReply = null;
        _showTips = false;
      });

      String localReply = "";
      
      if (_scanMode == 2) {
        // --- MODE 2: LOCAL (Offline TFLite) ---
        if (kDebugMode) print('🤖 [ML] Using Local TFLite Model...');
        final result = await _classificationService.classifyImage(bytes);
        final String label = result['label'];
        final num confidence = result['confidence'] ?? 0.0;
        
        if (label == "Error" || label == "Invalid Image" || confidence < 0.2) {
           localReply = 'Not Waste detected';
        } else {
           localReply = """
## Classification
$label (Local Model)

## Confidence
${(confidence * 100).toStringAsFixed(1)}%
""";
        }
      } else if (_scanMode == 1) {
        // --- MODE 1: HYBRID (Render Primary + Gemini Fallback) ---
        if (kDebugMode) print('☁️ [ML] Starting Hybrid Scan (Render Primary)...');
        
        Map<String, dynamic>? result;
        bool usedGemini = false;
        
        try {
          // 1. Try Render with a short 10s timeout (to catch Cold Boot)
          result = await _externalAiService.classifyImage(bytes, timeout: const Duration(seconds: 10));
          
          final num confidence = result['confidence'] ?? 0.0;
          final String rawLabel = result['label'] ?? 'Error';

          // 2. Check if we should fall back to Gemini
          if (rawLabel.startsWith('Error') || rawLabel.startsWith('Exception') || confidence < 0.75) {
            if (kDebugMode) print('⚠️ [ML] Render unsure or slow (Confidence: $confidence). Falling back to Gemini...');
            usedGemini = true;
          }
        } catch (e) {
            if (kDebugMode) print('⏳ [ML] Render timed out or failed ($e). Switching to Gemini Expert...');
            usedGemini = true;
        }

        if (usedGemini) {
          setState(() { localReply = "## Classification\nConsulting Expert AI..."; });
          final String prompt = '''
            Analyze this waste item for sorting.
            Classify it strictly as: Biodegradable, Non-Biodegradable (Recyclable), Non-Biodegradable (Residual), or Hazardous.
            Format: ## Classification\n[Category]\n\n## Note\n[A short 1-sentence sorting tip]''';
          
          try {
            localReply = await _chatService.sendMessageWithImages(prompt, [DataPart('image/jpeg', bytes)]);
            localReply += "\n\n*(Verified by Expert AI)*";
          } catch (e) {
            // Last resort: show whatever Render got, or an error
            final String rawLabel = result?['label'] ?? 'Connection Error';
            localReply = "## Classification\n${_externalAiService.mapLabelToCategory(rawLabel)}\n\n## Note\nCould not reach Expert AI. Using standard prediction.";
          }
        } else {
          // Render was fast and confident!
          final String rawLabel = result!['label'];
          final String mappedCategory = _externalAiService.mapLabelToCategory(rawLabel);
          localReply = "## Classification\n$mappedCategory \n\n## Detected Material\n${rawLabel[0].toUpperCase()}${rawLabel.substring(1)} (Specialist AI)";
        }
      } else {
        // --- MODE 0: GEMINI (Cloud Expert) ---
        try {
          final String prompt = '''
  You are EcoSched Expert. Analyze this image for waste classification in Tago.
  If the image is extremely blurry, out of focus, or you cannot clearly see any recognizable object, reply EXACTLY with "BLURRY_IMAGE_DETECTED" and nothing else.
  Otherwise, provide a professional, extremely accurate response formatted exactly like this:
  
  ## Classification
  State the specific waste category here.
  
  ## Classification
  State the specific waste category here.
  ''';
          localReply = await _chatService.sendMessageWithImages(
            prompt,
            [DataPart('image/jpeg', bytes)],
          );
        } catch (e) {
          if (kDebugMode) print('⚠️ Gemini API Failed, falling back to External: $e');
          // Fallback to External if Gemini fails
          final result = await _externalAiService.classifyImage(bytes);
          final String rawLabel = result['label'];
          localReply = "## Classification\n${_externalAiService.mapLabelToCategory(rawLabel)}\n\n## Note\nThis prediction was made using our Custom AI fallback.";
        }
      }
      
      if (mounted) {
        setState(() {
          _lastReply = localReply;
        });
        
        // AUTOMATICALLY trigger the database save
        _returnResultToCaller();
        
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
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: _isSaving,
        builder: (context, isSaving, _) {
          return _GlassResultSheet(
            reply: _lastReply!,
            isSaving: isSaving,
            onUseResult: () => Navigator.pop(context),
            onScanAgain: () {
              Navigator.pop(context);
              setState(() {
                _capturedImageBytes = null;
                _lastReply = null;
              });
            },
          );
        },
      ),
    );
  }

  void _showHowItWorks() {
    // This method is now hidden to simplify the UI
  }

  @override
  void dispose() {
    _controller?.dispose();
    _classificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('EcoScan Live'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black, // Professional camera background
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Preview or Captured Image (Full Screen)
              if (_capturedImageBytes != null)
                Positioned.fill(
                  child: Image.memory(_capturedImageBytes!, fit: BoxFit.cover),
                )
              else
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize?.height ?? 1080,
                      height: _controller!.value.previewSize?.width ?? 1920,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),

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
                          'Starting AI Engine...',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Render services spin down after inactivity. On your first scan, please wait up to 60 seconds for the "Cold Boot".',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                            textAlign: TextAlign.center,
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
                'Point at any waste item and tap the button. EcoSched will identify if it is Biodegradable, Non-Biodegradable, or Recyclable.',
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
  final bool isSaving;
  final VoidCallback onUseResult;
  final VoidCallback onScanAgain;

  const _GlassResultSheet({
    required this.reply,
    required this.isSaving,
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
                  if (reply.contains('BLURRY_IMAGE_DETECTED'))
                     _buildBlurryContent(context)
                  else if (reply.contains('Not Waste detected'))
                     _buildErrorContent(context)
                  else
                     _buildStructuredContent(context),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlurryContent(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.blur_on_rounded, size: 64, color: Colors.blueGrey),
        const SizedBox(height: 16),
        Text(
          'Image is Blurry',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'We couldn\'t get a clear picture. Please hold your camera steady and scan again.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
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
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                'Scan Successful',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                                isSaving ? '☁️ Saving to cloud...' : '✅ Saved to history',
                                style: TextStyle(
                                    color: isSaving ? Colors.orangeAccent : AppTheme.primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                ),
                            ),
                        ],
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
