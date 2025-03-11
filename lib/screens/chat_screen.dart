import 'dart:convert';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'VehicleDetailsScreen.dart';
import 'config.dart';

const String openAIAPIKey = "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"; // 🔹 Replace with your OpenAI API Key

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  final HitsSearcher _productsSearcher = HitsSearcher(
    applicationID: AlgoliaConfig.applicationId,
    apiKey: AlgoliaConfig.apiKey,
    indexName: AlgoliaConfig.indexName,
  );

  Map<String, String> _conversationState = {};

  @override
  void initState() {
    super.initState();
    _startChatWithAI();
  }

  void _startChatWithAI() {
    _addBotMessage("👋 Hello! I'm your AI assistant. What kind of car are you looking for?", quickReplies: [
      "Find a car",
      "Check latest models",
      "Compare vehicles"
    ]);
  }

  void _processUserMessage(String message) {
    _addUserMessage(message);
    message = message.toLowerCase().trim();

    if (!_conversationState.containsKey('make')) {
      _conversationState['make'] = message;
      _addBotMessage("Got it! Which model are you interested in?");
      return;
    }

    if (!_conversationState.containsKey('model')) {
      _conversationState['model'] = message;
      _addBotMessage("Do you prefer Petrol or Diesel?");
      return;
    }

    if (!_conversationState.containsKey('fuelType')) {
      _conversationState['fuelType'] = message;
      _addBotMessage("Do you have a preferred color?");
      return;
    }

    if (!_conversationState.containsKey('color')) {
      _conversationState['color'] = message;
      _searchFilteredVehicles();
      return;
    }
  }

  void _searchFilteredVehicles() {
    _addBotMessage("🔍 Searching for the perfect car...", isThinking: true);

    Future.delayed(const Duration(seconds: 2), () async {
      _productsSearcher.applyState(
            (state) => state.copyWith(
          query:
          "${_conversationState['make']} ${_conversationState['model']} ${_conversationState['fuelType']} ${_conversationState['color']}",
          hitsPerPage: 8,
        ),
      );

      final response = await _productsSearcher.responses.first;

      setState(() {
        _messages.removeWhere((m) => (m['isThinking'] ?? false) == true);

        if (response.hits.isNotEmpty) {
          _addBotMessage("✅ I found the perfect match for you!", vehicles: response.hits);
        } else {
          _askChatGPTForAlternatives();
        }
      });

      _conversationState.clear();
    });
  }

  void _askChatGPTForAlternatives() async {
    _addBotMessage("🤖 Let me check with my AI database...", isThinking: true);

    final aiResponse = await _getChatGPTResponse(
        "I am looking for a ${_conversationState['make']} ${_conversationState['model']} in ${_conversationState['color']} color with a ${_conversationState['fuelType']} engine, but I couldn't find a match. Can you suggest alternatives?");

    setState(() {
      _messages.removeWhere((m) => (m['isThinking'] ?? false) == true);
      _addBotMessage(aiResponse, quickReplies: ["Try another search", "Contact Support"]);
    });
  }

  Future<String> _getChatGPTResponse(String userMessage) async {
    const String apiUrl = "https://api.openai.com/v1/chat/completions";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Authorization": "Bearer $openAIAPIKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": "You are an AI assistant helping users find cars."},
          {"role": "user", "content": userMessage},
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"].trim();
    } else {
      return "❌ Sorry, I couldn't process that request. Please try again.";
    }
  }

  void _addBotMessage(String text, {bool isThinking = false, List<String>? quickReplies, List<Hit>? vehicles}) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': false,
        'isThinking': isThinking,
        'quickReplies': quickReplies,
        'vehicles': vehicles,
        'timestamp': DateTime.now(),
      });
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': true, 'timestamp': DateTime.now()});
      _controller.clear();
    });

    if (text.toLowerCase().contains("contact support")) {
      _sendToWhatsApp();
    }
  }

  void _sendToWhatsApp() async {
    final String phone = "+254748222222";
    final String message = Uri.encodeComponent("Hi, I need help finding a vehicle.");
    final String whatsappLink = "https://wa.me/$phone?text=$message";

    if (!await launchUrlString(whatsappLink, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isUser = message['isUser'] ?? false;
    bool isThinking = message['isThinking'] ?? false;
    String time = DateFormat('HH:mm a').format(message['timestamp'] ?? DateTime.now());

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
            child: isThinking
                ? SpinKitThreeBounce(color: Colors.black54, size: 18)
                : Text(
              message['text'] ?? "Unknown message",
              style: TextStyle(color: isUser ? Colors.white : Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Text(time, style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
          if (message['vehicles'] != null) _buildVehicleList(message['vehicles']),
          if (message['quickReplies'] != null) _buildQuickReplies(message['quickReplies']),
        ],
      ),
    );
  }
  Widget _buildQuickReplies(List<String> replies) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 5),
      child: Wrap(
        spacing: 10,
        children: replies.map((reply) => ElevatedButton(onPressed: () => _processUserMessage(reply), child: Text(reply))).toList(),
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
          Expanded(child: ListView.builder(controller: _scrollController, itemCount: _messages.length, itemBuilder: (context, index) => _buildMessageBubble(_messages[index]))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [Expanded(child: TextField(controller: _controller, onSubmitted: _processUserMessage)), IconButton(icon: const Icon(Icons.send), onPressed: () => _processUserMessage(_controller.text))],
            ),
          ),
        ],
      ),
    );
  }
}
