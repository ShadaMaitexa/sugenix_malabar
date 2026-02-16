import 'package:flutter/material.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/services/chat_history_service.dart';
import 'package:sugenix/services/gemini_service.dart';
import 'package:sugenix/services/glucose_service.dart';
import 'package:sugenix/services/user_context_service.dart';
import 'package:intl/intl.dart';
import 'package:sugenix/services/language_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatHistoryService _chatService = ChatHistoryService();
  final GlucoseService _glucoseService = GlucoseService();
  final UserContextService _userContextService = UserContextService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      _chatService.getChatHistory(limit: 50).listen((firestoreMessages) {
        if (mounted && _isLoading) {
          setState(() {
            _messages.clear();
            if (firestoreMessages.isEmpty) {
              _addWelcomeMessage();
            } else {
              for (var msg in firestoreMessages) {
                _messages.add(ChatMessage(
                  text: msg['text'] as String? ?? '',
                  isUser: msg['isUser'] as bool? ?? false,
                  timestamp: msg['timestamp'] is DateTime
                      ? msg['timestamp'] as DateTime
                      : DateTime.now(),
                ));
              }
            }
            _isLoading = false;
          });
          _scrollToBottom();
        }
      });
    } catch (e) {
      setState(() {
        _addWelcomeMessage();
        _isLoading = false;
      });
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        text:
            "Hello! I'm your AI health assistant. I can help you with diabetes-related questions, medication information, dietary advice, and general health guidance. How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isGenerating) return;

    final userMessage = _messageController.text.trim();

    // Save user message to Firebase
    await _chatService.saveMessage(text: userMessage, isUser: true);

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isGenerating = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get comprehensive user context from Firestore for personalized recommendations
      String personalizedContext = '';
      try {
        personalizedContext =
            await _userContextService.buildPersonalizedContext();
        print('User context loaded: ${personalizedContext.length} characters');
      } catch (e) {
        print('Error building user context: $e');
        // Fallback to basic glucose context
        try {
          final readings = await _glucoseService.getGlucoseReadingsByDateRange(
            startDate: DateTime.now().subtract(const Duration(days: 7)),
            endDate: DateTime.now(),
          );
          if (readings.isNotEmpty) {
            final latest = readings.first;
            personalizedContext =
                'Recent glucose reading: ${latest['value']} mg/dL (${latest['type']})';
          }
        } catch (e2) {
          print('Error getting glucose readings: $e2');
          // Continue without context if unavailable
        }
      }

      // Generate AI response using Gemini with personalized context
      // The AI will use this context to provide diet and exercise recommendations
      final aiResponse =
          await GeminiService.chat(userMessage, context: personalizedContext);

      if (mounted) {
        // Save AI response to Firebase
        await _chatService.saveMessage(text: aiResponse, isUser: false);

        setState(() {
          _messages.add(ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        // Fallback response
        final fallbackResponse = _getFallbackResponse(userMessage);
        await _chatService.saveMessage(text: fallbackResponse, isUser: false);

        setState(() {
          _messages.add(ChatMessage(
            text: fallbackResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isGenerating = false;
        });
        _scrollToBottom();

        // Show a less intrusive message - only log the error, don't show snackbar
        // The fallback response is already shown to the user
        print('AI service error: ${e.toString()}');
      }
    }
  }

  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    final fallbackTopics = [
      {
        'keywords': ['glucose', 'blood sugar', 'sugar'],
        'response':
            "For glucose management, monitor your levels regularly. Fasting targets are 70–99 mg/dL and post-meal ideally stays below 140 mg/dL. Log your readings in the Glucose module so the AI can spot trends and flag risky patterns."
      },
      {
        'keywords': ['medication', 'medicine', 'drug'],
        'response':
            "Take diabetes medications exactly as prescribed and set reminders so doses are never missed. Use the Medicine Scanner to review instructions, and speak with your doctor before changing timing or dosage."
      },
      {
        'keywords': ['diet', 'food', 'eat', 'meal'],
        'response':
            "Build plates with half vegetables, one quarter lean protein, and one quarter whole grains. Space meals 3–4 hours apart, stay hydrated, and carry a fast-acting carb snack in case your glucose dips unexpectedly."
      },
      {
        'keywords': ['exercise', 'workout', 'activity', 'walk'],
        'response':
            "Aim for 150 minutes of moderate movement each week—brisk walking, cycling, or low-impact aerobics all help insulin work better. Check glucose before and after workouts and keep water plus a small carb snack handy."
      },
      {
        'keywords': ['stress', 'anxiety', 'mental'],
        'response':
            "Stress hormones can raise glucose. Add short breathing breaks, gentle stretches, or journaling after meals. If stress feels overwhelming, consider speaking with a counselor or mental-health specialist."
      },
      {
        'keywords': ['sleep', 'insomnia', 'rest'],
        'response':
            "Consistent 7–8 hour sleep windows improve insulin sensitivity. Dim screens an hour before bed, keep caffeine to mornings, and try light stretches or meditation to signal your body that it’s time to rest."
      },
      {
        'keywords': ['foot', 'feet', 'wound'],
        'response':
            "Inspect your feet daily for cuts, redness, or swelling. Wash, dry thoroughly, moisturize the tops (not between toes), and wear cushioned footwear. Report any sores or numbness to your care team promptly."
      },
      {
        'keywords': ['insulin', 'injection', 'pen'],
        'response':
            "Rotate injection sites (abdomen, thighs, upper arms) to avoid lipodystrophy. Store insulin within the recommended temperature range and discard any vial beyond its in-use window to keep dosing accurate."
      },
      {
        'keywords': ['travel', 'trip', 'flight'],
        'response':
            "Pack double the medicines and supplies you expect to use, keep them in carry-on luggage, and adjust dosing schedules gradually when crossing time zones. Check glucose more often on travel days."
      },
      {
        'keywords': ['emergency', 'urgent', 'help'],
        'response':
            "If you have severe symptoms, use the Emergency SOS feature or contact local medical services immediately. Share your latest readings and medication list so responders can support you faster."
      },
    ];

    for (final topic in fallbackTopics) {
      final keywords = (topic['keywords'] as List<String>);
      if (keywords.any((k) => lowerMessage.contains(k))) {
        return topic['response'] as String;
      }
    }

    return '''
Thanks for reaching out! I can guide you on glucose tracking, medication routines, diet, activity, hydration, stress relief, or emergency planning. 
• Tell me a recent glucose trend and I’ll interpret it.
• Ask for meal or workout ideas tailored to your readings.
• Say “share tips” plus a topic (sleep, travel, foot care) for focused guidance.''';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: Color(0xFF0C4556),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            StreamBuilder<String>(
              stream: LanguageService.currentLanguageStream,
              builder: (context, snapshot) {
                final languageCode = snapshot.data ?? 'en';
                final title = LanguageService.translate('ai_assistant', languageCode);
                return Text(
                  title == 'ai_assistant' ? 'AI Assistant' : title,
                  style: const TextStyle(
                    color: Color(0xFF0C4556),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: ResponsiveHelper.getResponsivePadding(context),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF0C4556).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              size: 60,
              color: Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "AI Health Assistant",
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Ask me anything about diabetes management, medications, diet, exercise, or general health.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556),
                borderRadius: BorderRadius.circular(17.5),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF0C4556) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                      color: message.isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(17.5),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type your message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C4556),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isGenerating ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
