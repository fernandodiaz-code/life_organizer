class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  static ChatMessage user(String content) => ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );

  static ChatMessage jarvis(String content) => ChatMessage(
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
      );

  static ChatMessage loading() => ChatMessage(
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      );
}
