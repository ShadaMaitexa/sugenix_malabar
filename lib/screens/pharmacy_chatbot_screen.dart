import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugenix/services/pharmacy_chatbot_service.dart';

class PharmacyChatbotScreen extends StatefulWidget {
  const PharmacyChatbotScreen({super.key});

  @override
  State<PharmacyChatbotScreen> createState() => _PharmacyChatbotScreenState();
}

class _PharmacyChatbotScreenState extends State<PharmacyChatbotScreen> {
  final PharmacyChatbotService _chatbotService = PharmacyChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  void _loadChatHistory() async {
    final history = await _chatbotService.getChatHistory();
    setState(() {
      _messages = history.reversed.toList();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to UI
    setState(() {
      _messages.add({
        'userMessage': message,
        'botResponse': '',
        'timestamp': Timestamp.now(),
        'isUser': true,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get response from chatbot service
      final response = await _chatbotService.sendMessage(message);

      // Save chat to Firebase
      await _chatbotService.saveChatMessage(
        message: message,
        response: response,
        isUser: true,
      );

      // Add bot response to UI
      setState(() {
        _messages.add({
          'userMessage': message,
          'botResponse': response,
          'timestamp': Timestamp.now(),
          'isUser': false,
        });
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'userMessage': message,
          'botResponse': 'Error: ${e.toString()}',
          'timestamp': Timestamp.now(),
          'isUser': false,
        });
        _isLoading = false;
      });
    }
  }

  void _showQuickReplyOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quick Replies',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Pharmacy Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '💊 Pharmacy Products',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0C4556),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _quickReplyButton(
                '📋 Available Medicines',
                'What medicines do you have in stock?',
              ),
              const SizedBox(height: 8),
              _quickReplyButton(
                '💊 Diabetes Medicines',
                'What diabetes management medicines are available?',
              ),
              const SizedBox(height: 8),
              _quickReplyButton(
                '💰 Price Comparison',
                'Can you show me the price comparison for diabetes medicines?',
              ),
              const SizedBox(height: 8),
              _quickReplyButton(
                '🔍 Search Medicine',
                'Do you have Metformin in stock?',
              ),
              const SizedBox(height: 8),
              _quickReplyButton(
                '⚠️ Side Effects',
                'What are the side effects of Insulin?',
              ),
              const SizedBox(height: 16),
              // Glucose Management Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '📊 Glucose Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0C4556),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _quickReplyButton(
                '📈 My Glucose Levels',
                'What do my recent glucose readings tell you? Analyze my glucose levels.',
              ),
              const SizedBox(height: 8),
              _quickReplyButton(
                '⚠️ Low Glucose Help',
                'How should I handle low glucose levels? What are the symptoms and treatment?',
              ),
              const SizedBox(height: 8),
              _quickReplyButton(
                '⚠️ High Glucose Help',
                'How should I handle high glucose levels? What should I do?',
              ),
              const SizedBox(height: 8),
              _quickReplyButton(
                '🎯 Normal Glucose Range',
                'What are the normal glucose levels I should aim for?',
              ),
              const SizedBox(height: 8),
              _quickReplyButton(
                '💊 Medicines & Glucose',
                'Which medicines help control blood glucose? Tell me about insulin and metformin.',
              ),
              const SizedBox(height: 16),
              // Combined Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '🏥 Comprehensive Advice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0C4556),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _quickReplyButton(
                '🏥 Complete Diabetes Advice',
                'Give me comprehensive diabetes management advice based on my glucose readings and available medicines.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickReplyButton(String label, String message) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _sendMessage(message);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C4556),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C4556),
        elevation: 0,
        title: const Text(
          'Pharmacy & Glucose Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('📊 Glucose Analysis'),
                onTap: () {
                  _showGlucoseAnalysis();
                },
              ),
              PopupMenuItem(
                child: const Text('💊 Medicine Recommendations'),
                onTap: () {
                  _showRecommendations();
                },
              ),
              PopupMenuItem(
                child: const Text('🏥 Comprehensive Advice'),
                onTap: () {
                  _showComprehensiveAdvice();
                },
              ),
              PopupMenuItem(
                child: const Text('🗑️ Clear History'),
                onTap: () {
                  _showClearHistoryDialog();
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation with our\nPharmacy Assistant',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _showQuickReplyOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C4556),
                          ),
                          child: const Text(
                            'Quick Replies',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final userMsg = message['userMessage'] ?? '';
                      final botResponse = message['botResponse'] ?? '';

                      return Column(
                        children: [
                          // User Message
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C4556),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                userMsg,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          // Bot Response
                          if (botResponse.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  botResponse,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0C4556),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Assistant is typing...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about medicines...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _messageController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _messageController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading
                      ? null
                      : () => _sendMessage(_messageController.text),
                  backgroundColor: const Color(0xFF0C4556),
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _showQuickReplyOptions,
                  backgroundColor: Colors.grey[400],
                  mini: true,
                  child:
                      const Icon(Icons.lightbulb_outline, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _chatbotService.clearChatHistory();
              setState(() => _messages.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showRecommendations() async {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: _chatbotService.getDiabeticMedicineRecommendations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: const Text('💊 Diabetes Medicine Recommendations'),
              content: const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return AlertDialog(
            title: const Text('💊 Diabetes Medicine Recommendations'),
            content: SingleChildScrollView(
              child: Text(snapshot.data ?? 'Unable to load recommendations'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGlucoseAnalysis() async {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: _chatbotService.getGlucoseHealthAnalysis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: const Text('📊 Glucose Health Analysis'),
              content: const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return AlertDialog(
            title: const Text('📊 Glucose Health Analysis'),
            content: SingleChildScrollView(
              child: Text(snapshot.data ?? 'Unable to load glucose analysis'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComprehensiveAdvice() async {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: _chatbotService.getComprehensiveDiabetesAdvice(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: const Text('🏥 Comprehensive Diabetes Advice'),
              content: const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return AlertDialog(
            title: const Text('🏥 Comprehensive Diabetes Advice'),
            content: SingleChildScrollView(
              child: Text(snapshot.data ?? 'Unable to load advice'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
