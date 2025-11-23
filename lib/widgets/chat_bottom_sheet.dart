import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'live_scan_screen.dart';
import '../core/services/ai_chat_service.dart';
import '../core/error/error_handler.dart';
import '../core/theme/app_theme.dart';

class ChatBottomSheet extends StatefulWidget {
  final String apiKey;

  const ChatBottomSheet({super.key, required this.apiKey});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  late final AiChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<Content> _history = <Content>[];
  bool _isSending = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _chatService = AiChatService(widget.apiKey);
    _messages.add(ChatMessage(isUser: false, text: 'Hi! I\'m EcoSched Assistant for Tago, Surigao del Sur.'));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    String input = _textController.text.trim();
    if ((_selectedImageBytes == null && input.isEmpty) || _isSending) return;
    if (input.isEmpty && _selectedImageBytes != null) {
      input = 'Classify the waste item in the photo as biodegradable, non-biodegradable (recyclable or not), or hazardous. Provide a very short disposal tip for Tago.';
    }
    setState(() {
      _isSending = true;
      _messages.add(ChatMessage(isUser: true, text: input, imageBytes: _selectedImageBytes));
      _textController.clear();
    });
    try {
      String reply;
      if (_selectedImageBytes != null) {
        final DataPart img = DataPart('image/jpeg', _selectedImageBytes!);
        reply = await _chatService.sendMessageWithImages(input, [img], history: _history);
        _history.add(Content.multi([TextPart(input), img]));
      } else {
        reply = await _chatService.sendMessage(input, history: _history);
        _history.add(Content.text(input));
      }
      _history.add(Content.model([TextPart(reply)]));
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: reply));
        _selectedImageBytes = null;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: 'Sorry, I encountered an error. Please try again.'));
      });
      ErrorHandler.handleError(e, StackTrace.current, context: 'Chat send');
    } finally {
      setState(() {
        _isSending = false;
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _quickAsk(String prompt) {
    _textController.text = prompt;
    _handleSend();
  }

  Future<void> _pickImage() async {
    try {
      final PermissionStatus galleryStatus = await Permission.photos.request();
      final PermissionStatus cameraStatus = await Permission.camera.request();
      if (galleryStatus.isDenied && cameraStatus.isDenied) {
        return;
      }
      final ImagePicker picker = ImagePicker();
      final XFile? file = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    final XFile? img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    Navigator.of(context).pop(img);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    final XFile? img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                    Navigator.of(context).pop(img);
                  },
                ),
              ],
            ),
          );
        },
      );
      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      ErrorHandler.handleError(e, StackTrace.current, context: 'Pick image');
    }
  }

  Future<void> _openLiveScan() async {
    try {
      final result = await Navigator.of(context).push<LiveScanResult>(
        MaterialPageRoute(
          builder: (_) => LiveScanScreen(apiKey: widget.apiKey),
          fullscreenDialog: true,
        ),
      );
      if (result == null) return;
      // Add user image bubble
      setState(() {
        _messages.add(ChatMessage(isUser: true, text: 'Live scan', imageBytes: result.imageBytes));
      });
      // Add assistant reply and update history
      _history.add(Content.multi([TextPart('Live scan image'), DataPart('image/jpeg', result.imageBytes)]));
      _history.add(Content.model([TextPart(result.reply)]));
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: result.reply));
      });
    } catch (e) {
      ErrorHandler.handleError(e, StackTrace.current, context: 'Open live scan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.smart_toy, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(child: Text('EcoSched Assistant', style: theme.textTheme.titleMedium)),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _SuggestionChip(label: 'Pickup schedule', onTap: () => _quickAsk('What\'s the waste pickup schedule in Tago this week?')),
                    _SuggestionChip(label: 'Segregation rules', onTap: () => _quickAsk('What are the segregation rules in Tago?')),
                    _SuggestionChip(label: 'Report missed pickup', onTap: () => _quickAsk('How do I report a missed pickup in Tago?')),
                    _SuggestionChip(label: 'Drop-off points', onTap: () => _quickAsk('Where are the waste drop-off points in Tago?')),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final ChatMessage msg = _messages[index];
                  final bool isUser = msg.isUser;
                  final Color bubbleColor = isUser ? AppTheme.primaryGreen : theme.colorScheme.surfaceContainerHighest;
                  final Color textColor = isUser ? Colors.white : theme.colorScheme.onSurface;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.imageBytes != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                msg.imageBytes!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if ((msg.text ?? '').isNotEmpty) const SizedBox(height: 8),
                          ],
                          if ((msg.text ?? '').isNotEmpty)
                            Text(
                              msg.text!,
                              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            if (_selectedImageBytes != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attached photo • Will analyze for biodegradable/non-biodegradable/recyclable',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove photo',
                      onPressed: () => setState(() => _selectedImageBytes = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Add photo',
                    onPressed: _isSending ? null : _pickImage,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    color: AppTheme.primaryGreen,
                  ),
                  IconButton(
                    tooltip: 'Live scan',
                    onPressed: _isSending ? null : _openLiveScan,
                    icon: const Icon(Icons.videocam_outlined),
                    color: AppTheme.primaryGreen,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about Tago schedules, segregation, reporting...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _handleSend,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final bool isUser;
  final String? text;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.isUser,
    this.text,
    this.imageBytes,
  });
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: Theme.of(context).textTheme.bodySmall,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
    );
  }
}


