import 'dart:convert';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'VehicleDetailsScreen.dart';
import 'config.dart';
import '../services/openai_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
     _productsSearcher.responses.listen((response) {
      if (mounted) setState(() {});
    });
    _productsSearcher.connectFilterState(_filterState);
    super.initState();
    _addBotMessage("👋 Welcome to Alhusnain Motors! My name is Nathan, your sales representative. How can I assist you today?");
  }
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _openAI = OpenAIService();
  final _filterState = FilterState();
  final int _pageSize = 8;
  int _currentPageKey = 0;
  final HitsSearcher _productsSearcher = HitsSearcher(
    applicationID: AlgoliaConfig.applicationId,
    apiKey: AlgoliaConfig.apiKey,
    indexName: AlgoliaConfig.indexName,
  );


  bool _isLoading = false;

  void _processUserMessage(String message) async {
    _addUserMessage(message);
    _setLoading(true);

    try {
      // Send natural message and receive clean query string (e.g. "Toyota Vitz White 2018+")
      final aiQuery = await _openAI.sendMessage(message);

      // Basic check in case of OpenAI errors
      if (aiQuery.startsWith("❌") || aiQuery.startsWith("⚠️")) {
        _addBotMessage("🚫 AI Error: $aiQuery");
        return;
      }

      final query = aiQuery.trim();

      // Let user know what’s being searched
      _addBotMessage("🔍 Searching for: *$query*");

      // Apply query directly to Algolia
      _productsSearcher.applyState((state) => state.copyWith(
        query: query,
        page: _currentPageKey,
        hitsPerPage: _pageSize,
      ));

      final response = await _productsSearcher.responses.first;
      final isLastPage = response.hits.length < _pageSize;

      if (response.hits.isNotEmpty) {
        _addBotMessage("✅ Here are some results for *$query*:", vehicles: response.hits);
        if (!isLastPage) _currentPageKey += 1;
      } else {
        _addBotMessage("😕 No results found for *$query*. Want to try a different make or model?");
      }
    } catch (e) {
      _addBotMessage("❗ Couldn't process your request. Please try again.");
      debugPrint("AI or Query Error: $e");
    } finally {
      _setLoading(false);
    }
  }


  void _addBotMessage(String text, {List<Hit>? vehicles}) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': false,
        'vehicles': vehicles,
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _controller.clear();
    });
    _scrollToBottom();

    if (text.toLowerCase().contains("contact support")) {
      _sendToWhatsApp();
    }
  }

  void _setLoading(bool loading) {
    setState(() => _isLoading = loading);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendToWhatsApp() async {
    int hour = DateTime.now().hour;
    String greeting = (hour < 12) ? "Good morning" : (hour < 18) ? "Good afternoon" : "Good evening";

    String chatHistory = _messages.map((msg) {
      String sender = msg['isUser'] ? "You" : "AI Assistant";
      return "*$sender:* ${msg['text']}";
    }).join("\n\n");

    final String message = '''
    📢 *$greeting! I need help finding a vehicle.* 🚗  
    Here is our chat history:  
    $chatHistory    
    ''';

    final String phone = "+254748222222";
    final String whatsappLink = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    if (!await launchUrlString(whatsappLink, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isUser = message['isUser'] ?? false;
    String time = DateFormat('hh:mm a').format(message['timestamp'] ?? DateTime.now());

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.blueAccent : Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              message['text'] ?? "Unknown message",
              style: TextStyle(color: isUser ? Colors.white : Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(time, style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
          if (message['vehicles'] != null) _buildVehicleList(message['vehicles']),
        ],
      ),
    );
  }

  Widget _buildVehicleList(List<Hit> vehicles) {
    return Column(
      children: vehicles.map(_buildVehicleCard).toList(),
    );
  }

  Widget _buildVehicleCard(Hit vehicle) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CachedNetworkImage(imageUrl: vehicle['main_photo'] ?? '', width: 60),
        title: Text("${vehicle['make']} ${vehicle['model']}"),
        subtitle: Text("Year: ${vehicle['yr_of_mfg']} • Fuel: ${vehicle['fuel']}"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsScreen(vehicleId: vehicle['vehicle_id'].toString()),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SpinKitThreeBounce(color: Colors.black54, size: 18),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, onSubmitted: _processUserMessage)),
                IconButton(icon: const Icon(Icons.send), onPressed: () => _processUserMessage(_controller.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
