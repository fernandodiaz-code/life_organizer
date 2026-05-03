import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/chat_message.dart';
import '../../services/jarvis_service.dart';

class JarvisScreen extends StatefulWidget {
  const JarvisScreen({super.key});

  @override
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen> {
  final _messages = <ChatMessage>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _speech = SpeechToText();
  bool _sending = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastRecognizedWords = '';

  @override
  void initState() {
    super.initState();
    _addWelcome();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _ensureSpeechReady(showErrors: false);
    if (mounted) setState(() => _speechAvailable = available);
  }

  void _addWelcome() {
    _messages.add(ChatMessage.jarvis(
      'Hola, soy Jarvis. ¿En qué puedo ayudarte hoy?',
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _send([String? voiceText]) async {
    final text = voiceText ?? _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    if (voiceText == null) _inputCtrl.clear();
    setState(() {
      _messages.add(ChatMessage.user(text));
      _messages.add(ChatMessage.loading());
      _sending = true;
    });
    _scrollToBottom();

    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

    final response = await JarvisService.sendMessage(text, userId);

    if (mounted) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage.jarvis(response));
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _toggleMic() async {
    if (_sending) return;

    if (_isListening) {
      await _speech.stop();
      _finishVoiceInput();
      return;
    }

    final ready = await _ensureSpeechReady();
    if (!ready) return;

    String? esLocale;
    try {
      final locales = await _speech.locales();
      esLocale = locales
          .where((l) => l.localeId.startsWith('es'))
          .map((l) => l.localeId)
          .firstOrNull;
    } catch (_) {
      esLocale = null;
    }

    _lastRecognizedWords = '';
    setState(() => _isListening = true);

    try {
      await _speech.listen(
        onResult: (result) {
          _lastRecognizedWords = result.recognizedWords.trim();
          if (result.finalResult) {
            _finishVoiceInput();
          }
        },
        localeId: esLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
      if (!mounted) return;
      setState(() => _isListening = false);
      _showSnack('No pude activar el micrófono. Revisa los permisos.');
    }
  }

  Future<bool> _ensureSpeechReady({bool showErrors = true}) async {
    if (_speechAvailable && await _speech.hasPermission) return true;

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            _finishVoiceInput();
          }
        },
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (!mounted) return;
          setState(() => _isListening = false);
          if (showErrors) {
            _showSnack('No pude escuchar audio: ${error.errorMsg}');
          }
        },
      );

      if (mounted) setState(() => _speechAvailable = available);

      if (!available && showErrors) {
        _showSnack(
          'El reconocimiento de voz no está disponible o no tiene permiso.',
        );
      }
      return available;
    } catch (e) {
      debugPrint('Speech initialize error: $e');
      if (mounted) {
        setState(() => _speechAvailable = false);
        if (showErrors) {
          _showSnack('No pude inicializar el reconocimiento de voz.');
        }
      }
      return false;
    }
  }

  void _finishVoiceInput() {
    if (!_isListening) return;

    final text = _lastRecognizedWords.trim();
    if (mounted) setState(() => _isListening = false);
    _lastRecognizedWords = '';

    if (text.isNotEmpty) {
      _send(text);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyanGlow,
                border: Border.all(color: AppColors.cyan, width: 1.5),
              ),
              child: const Icon(Icons.smart_toy,
                  color: AppColors.cyan, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jarvis'),
                Text(
                  'Asistente personal',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpiar chat',
            onPressed: () => setState(() {
              _messages.clear();
              _addWelcome();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
            ),
          ),
          _InputBar(
            controller: _inputCtrl,
            sending: _sending,
            isListening: _isListening,
            speechAvailable: _speechAvailable,
            onSend: _send,
            onMicToggle: _toggleMic,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.cyanGlow : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.cyan.withValues(alpha: 0.5)
                      : AppColors.cardBorder,
                ),
              ),
              child: msg.isLoading
                  ? const _LoadingDots()
                  : Text(
                      msg.content,
                      style: TextStyle(
                        color: isUser
                            ? AppColors.cyan
                            : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat('HH:mm').format(msg.timestamp),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final val =
                (((_anim.value - delay) % 1 + 1) % 1);
            final opacity = val < 0.5 ? val * 2 : (1 - val) * 2;
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textMuted.withValues(alpha: 0.3 + opacity * 0.7),
              ),
            );
          }),
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool isListening;
  final bool speechAvailable;
  final void Function([String?]) onSend;
  final VoidCallback onMicToggle;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.isListening,
    required this.speechAvailable,
    required this.onSend,
    required this.onMicToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: isListening
                    ? 'Escuchando...'
                    : 'Escribe un mensaje...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isListening ? Colors.redAccent : AppColors.cyan,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: AppColors.card,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: speechAvailable
                ? 'Dictar mensaje'
                : 'Activar reconocimiento de voz',
            child: GestureDetector(
              onTap: sending ? null : onMicToggle,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: sending ? 0.45 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening ? AppColors.red : AppColors.card,
                    border: Border.all(
                      color: isListening
                          ? AppColors.red
                          : speechAvailable
                              ? AppColors.cardBorder
                              : AppColors.orange.withValues(alpha: 0.7),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: isListening
                        ? Colors.white
                        : speechAvailable
                            ? AppColors.textMuted
                            : AppColors.orange,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: sending ? AppColors.textMuted : AppColors.cyan,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : () => onSend(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded,
                      color: AppColors.bg, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
