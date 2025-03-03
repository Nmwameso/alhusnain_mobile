import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart'; // ✅ WhatsApp support

import 'VehicleDetailsScreen.dart';
import 'config.dart';


class SearchMetadata {
  final int nbHits;
  const SearchMetadata(this.nbHits);
  factory SearchMetadata.fromResponse(SearchResponse response) => SearchMetadata(response.nbHits);
}

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

  @override
  void initState() {
    super.initState();
    _startChatWithAI();
  }

  void _startChatWithAI() {
    Future.delayed(const Duration(seconds: 1), () {
      _addBotMessage("👋 Hello! I'm your AI assistant.");
      Future.delayed(const Duration(seconds: 2), () {
        _addBotMessage("How can I help you today?", quickReplies: [
          "Find a car",
          "Check latest models",
          "Compare vehicles"
        ]);
      });
    });
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
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _processUserMessage(String message) {
    _addUserMessage(message);

    if (message.toLowerCase() == "find a car") {
      _addBotMessage("What type of car are you looking for? (e.g., SUV, Toyota, Electric)");
    } else if (message.toLowerCase().contains("price") || message.toLowerCase().contains("cost")) {
      _handlePriceInquiry(message);
    } else if (message.length > 3) {
      _searchVehicles(message);
    } else {
      _addBotMessage("I'm here to help! Let me know what you're looking for. 🚗");
    }
  }

  void _searchVehicles(String query) {
    _addBotMessage("", isThinking: true);

    Future.delayed(const Duration(seconds: 2), () async {
      _productsSearcher.applyState(
            (state) => state.copyWith(query: query.trim(), page: 0, hitsPerPage: 3),
      );

      final response = await _productsSearcher.responses.first;

      setState(() {
        _messages.removeWhere((m) => (m['isThinking'] ?? false) == true);

        if (response.hits.isNotEmpty) {
          _addBotMessage("Here are some cars I found for you:", vehicles: response.hits);
        } else {
          _addBotMessage("I couldn't find any matching vehicles. Would you like to contact us on WhatsApp?", quickReplies: ["Yes, Contact Support"]);
        }
      });
    });
  }

  void _handlePriceInquiry(String message) {
    _addBotMessage("Let me check the price for you...");

    Future.delayed(const Duration(seconds: 2), () async {
      _productsSearcher.applyState(
            (state) => state.copyWith(query: message.trim(), page: 0, hitsPerPage: 1),
      );

      final response = await _productsSearcher.responses.first;

      setState(() {
        if (response.hits.isNotEmpty) {
          final vehicle = response.hits.first;
          _addBotMessage(
            "The price of the ${vehicle['make']} ${vehicle['model']} (${vehicle['yr_of_mfg']}) is ${vehicle['price']} EUR. Would you like more details?",
            quickReplies: ["Yes, Contact Support"],
          );
        } else {
          _addBotMessage("I couldn't find the price. Would you like to contact us on WhatsApp?", quickReplies: ["Yes, Contact Support"]);
        }
      });
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': true, 'timestamp': DateTime.now()});
      _controller.clear();
    });

    if (text == "Yes, Contact Support") {
      _sendToWhatsApp();
    }
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

🔗 *Please assist me with my request.*  
''';

    final String phone = "+254748222222"; // ✅ Ensure the number is in international format
    final String whatsappLink = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    if (!await launchUrlString(whatsappLink, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isUser = message['isUser'] ?? false; // ✅ Fix: Prevent null error
    bool isThinking = message['isThinking'] ?? false; // ✅ Fix: Prevent null error
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
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(15),
              ),
            ),
            child: isThinking
                ? SpinKitThreeBounce(color: Colors.black54, size: 18) // ✅ AI typing animation
                : Text(
              message['text'] ?? "Unknown message", // ✅ Fix: Prevents null text
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
        children: replies
            .map((reply) => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey[50],
            foregroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () => _processUserMessage(reply),
          child: Text(reply),
        ))
            .toList(),
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
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsScreen(
                vehicleId: vehicle['vehicle_id'].toString(),
              ),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: vehicle['main_photo'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 100,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white, height: 140),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    height: 140,
                    child: const Center(
                      child: Icon(Icons.directions_car, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Year', vehicle['yr_of_mfg']?.toString() ?? 'N/A'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Fuel', vehicle['fuel']?.toString() ?? 'N/A'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Mileage', '${vehicle['mileage']} km'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Trans', vehicle['transm']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
      ],
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
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onSubmitted: (value) => _processUserMessage(value),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: () => _processUserMessage(_controller.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}