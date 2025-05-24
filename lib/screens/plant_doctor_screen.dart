import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io'; // Import dart:io for File
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

// API Configuration
const String PLANT_ID_API_KEY = 'ZJdJrTuQGq2QUQNHIVZ32pg2Trmhl4jdrTTYyc8A76Mf2X2UGu';
const String PLANT_ID_API_URL = 'https://api.plant.id/v2/identify';
const String GEMINI_API_KEY = 'AIzaSyArcPvETiGsrZBligburcY8A53hlRCLeD4';
const String BACKEND_URL = 'http://localhost:3000/api'; // Update with your backend URL

// Define a simple ChatMessage class
enum MessageType { text, image }

class ChatMessage {
  final String? text;
  final String? imagePath;
  final bool isUserMessage;
  final MessageType type;

  ChatMessage({this.text, this.imagePath, required this.isUserMessage, required this.type});
}

class PlantDoctorScreen extends StatefulWidget {
  const PlantDoctorScreen({super.key});

  @override
  State<PlantDoctorScreen> createState() => _PlantDoctorScreenState();
}

class _PlantDoctorScreenState extends State<PlantDoctorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  late GenerativeModel _model;
  List<Map<String, dynamic>> _searchHistory = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: GEMINI_API_KEY,
    );
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request camera permission
      PermissionStatus cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to take photos')),
        );
        return false;
      }

      // Request microphone permission
      PermissionStatus microphoneStatus = await Permission.microphone.request();
      if (!microphoneStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice input')),
        );
        return false;
      }

      // Request storage permissions
      if (await Permission.storage.request().isGranted ||
          await Permission.photos.request().isGranted ||
          await Permission.mediaLibrary.request().isGranted) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to access photos')),
        );
        return false;
      }
    }
    return true;
  }

  void _startListening() async {
    bool granted = await _requestPermissions();
    if (!granted) return;

    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  Future<String> _getGeminiResponse(String userMessage) async {
    try {
      final content = [
        Content.text('''You are a plant expert assistant. Please provide accurate and helpful information about plants, diseases, and care.
        User question: $userMessage''')
      ];
      
      final response = await _model.generateContent(content);
      return response.text ?? "I apologize, but I couldn't generate a response at this time.";
    } catch (e) {
      print('Error getting Gemini response: $e');
      return "I apologize, but I encountered an error while processing your request.";
    }
  }

  Future<void> _analyzePlantImage(String imagePath) async {
    try {
      // Save search history
      await _saveSearchHistory('Plant Image Analysis', 'image');

      // Show loading message
      _addMessage(ChatMessage(
        text: "Analyzing your plant image...",
        isUserMessage: false,
        type: MessageType.text,
      ));

      final plantIdRequest = http.MultipartRequest(
        'POST',
        Uri.parse(PLANT_ID_API_URL),
      );
      plantIdRequest.headers['Api-Key'] = PLANT_ID_API_KEY;
      plantIdRequest.fields['organs'] = 'leaf';
      plantIdRequest.fields['details'] = 'common_names,url,description,care,health,usage,propagation_methods,edible_parts,watering,fertilization,soil,light,humidity,temperature,pruning,repotting,air_purifying,toxicity,medicinal_uses,poisonous_to_humans,poisonous_to_pets,flowers,leaf,stem,root,seed,fruit,hardiness,maintenance,watering_needs,fertilization_needs,soil_needs,light_needs,humidity_needs,temperature_needs,pruning_needs,repotting_needs,air_purifying_needs,toxicity_needs,medicinal_uses_needs,poisonous_to_humans_needs,poisonous_to_pets_needs,flowers_needs,leaf_needs,stem_needs,root_needs,seed_needs,fruit_needs,hardiness_needs,maintenance_needs';

      plantIdRequest.files.add(await http.MultipartFile.fromPath('images', imagePath));

      final plantIdStreamedResponse = await plantIdRequest.send();
      final plantIdResponse = await http.Response.fromStream(plantIdStreamedResponse);

      if (plantIdResponse.statusCode == 200) {
        final plantIdData = json.decode(plantIdResponse.body);
        final suggestions = plantIdData['suggestions'];
        if (suggestions != null && suggestions.isNotEmpty) {
          final bestMatch = suggestions[0];
          final plantDetails = bestMatch['plant_details'] ?? {};
          final health = plantDetails['health'] ?? {};
          
          String plantInfo = '''
Plant Name: ${bestMatch['plant_name']}

Disease Information:
${health['disease'] ?? 'No specific disease detected'}

Plant Details:
• Common Names: ${plantDetails['common_names']?.join(', ') ?? 'Not available'}
• Description: ${plantDetails['description'] ?? 'Not available'}

Care Instructions:
• Watering: ${plantDetails['watering'] ?? 'Not available'}
• Light: ${plantDetails['light'] ?? 'Not available'}
• Soil: ${plantDetails['soil'] ?? 'Not available'}
• Temperature: ${plantDetails['temperature'] ?? 'Not available'}
• Humidity: ${plantDetails['humidity'] ?? 'Not available'}

Maintenance:
• Fertilization: ${plantDetails['fertilization'] ?? 'Not available'}
• Pruning: ${plantDetails['pruning'] ?? 'Not available'}
• Repotting: ${plantDetails['repotting'] ?? 'Not available'}

Additional Information:
• Propagation: ${plantDetails['propagation_methods'] ?? 'Not available'}
• Air Purifying: ${plantDetails['air_purifying'] ?? 'Not available'}
• Toxicity: ${plantDetails['toxicity'] ?? 'Not available'}
''';

          // Get additional insights from Gemini
          String geminiPrompt = '''
Based on the following plant information, provide additional insights, care tips, and potential solutions for any detected issues:

$plantInfo

Please provide:
1. Specific care recommendations
2. Common problems and solutions
3. Best practices for maintaining this plant
''';

          final geminiResponse = await _getGeminiResponse(geminiPrompt);
          
          _addMessage(ChatMessage(
            text: plantInfo + "\n\nAdditional Expert Insights:\n" + geminiResponse,
            isUserMessage: false,
            type: MessageType.text,
          ));
        } else {
          _addMessage(ChatMessage(
            text: "Plant.id could not identify the plant or disease.",
            isUserMessage: false,
            type: MessageType.text,
          ));
        }
      } else {
        _addMessage(ChatMessage(
          text: "Plant.id API Error: ${plantIdResponse.statusCode}. Body: ${plantIdResponse.body}",
          isUserMessage: false,
          type: MessageType.text,
        ));
      }
    } catch (e) {
      print('Error analyzing image: $e');
      _addMessage(ChatMessage(
        text: "Sorry, I encountered an error while analyzing the image: ${e.toString()}",
        isUserMessage: false,
        type: MessageType.text,
      ));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      bool granted = await _requestPermissions();
      if (!granted) {
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null) {
        // Add user's image message
        _addMessage(ChatMessage(
          imagePath: image.path,
          isUserMessage: true,
          type: MessageType.image,
        ));

        // Show loading message
        _addMessage(ChatMessage(
          text: "Analyzing your plant image...",
          isUserMessage: false,
          type: MessageType.text,
        ));

        // Analyze the image using the API
        await _analyzePlantImage(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  void _sendTextMessage() async {
    if (_textController.text.trim().isNotEmpty) {
      String userMessage = _textController.text;
      _addMessage(ChatMessage(
        text: userMessage,
        isUserMessage: true,
        type: MessageType.text,
      ));
      
      _textController.clear();
      
      // Save search history
      await _saveSearchHistory(userMessage, 'text');
      
      // Show loading message
      _addMessage(ChatMessage(
        text: "Thinking...",
        isUserMessage: false,
        type: MessageType.text,
      ));

      // Get response from Gemini
      String response = await _getGeminiResponse(userMessage);
      
      // Remove the loading message
      setState(() {
        _messages.removeLast();
      });
      
      // Add the actual response
      _addMessage(ChatMessage(
        text: response,
        isUserMessage: false,
        type: MessageType.text,
      ));
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final response = await http.get(Uri.parse('$BACKEND_URL/search-history'));
      if (response.statusCode == 200) {
        setState(() {
          _searchHistory = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  Future<void> _saveSearchHistory(String query, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$BACKEND_URL/search-history'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode == 201) {
        await _loadSearchHistory();
      }
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          title: const Text(
            'Plant Doctor',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.green,
          elevation: 0,
          bottom: _selectedIndex == 0 ? TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.cloud),
                text: 'Online Info',
              ),
              Tab(
                icon: Icon(Icons.offline_pin),
                text: 'Offline Info',
              ),
            ],
          ) : null,
          actions: [
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Colors.green,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.green,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.agriculture,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kisan Mitra',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              ExpansionTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(initialSection: 'language'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(initialSection: 'notifications'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Theme'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(initialSection: 'theme'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.support),
                title: const Text('Support'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Support'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Contact us at:'),
                          const SizedBox(height: 8),
                          const Text('Email: support@kisanmitra.com'),
                          const SizedBox(height: 8),
                          const Text('Phone: +91 1800-XXX-XXXX'),
                          const SizedBox(height: 16),
                          const Text('Working Hours:'),
                          const Text('Monday - Friday: 9:00 AM - 6:00 PM'),
                          const Text('Saturday: 9:00 AM - 1:00 PM'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Help Center'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('How to use Plant Doctor:'),
                          const SizedBox(height: 8),
                          const Text('1. Take a photo of your plant'),
                          const Text('2. Ask questions about plant care'),
                          const Text('3. Get instant expert advice'),
                          const SizedBox(height: 16),
                          const Text('For more help:'),
                          const Text('• Visit our website: www.kisanmitra.com/help'),
                          const Text('• Watch tutorial videos'),
                          const Text('• Read our FAQ section'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _loadSearchHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Search history refreshed')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_searchHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recent searches',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ..._buildSearchHistoryList(),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildOnlineInfoTab(),
                _buildOfflineInfoTab(),
              ],
            ),
            _buildCommunityTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services),
              label: 'Plant Doctor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchHistoryList() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    final recentSearches = _searchHistory.where((search) {
      final searchDate = DateTime.parse(search['timestamp']);
      return searchDate.isAfter(sevenDaysAgo);
    }).toList();

    recentSearches.sort((a, b) => 
      DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

    return recentSearches.map((search) {
      final searchDate = DateTime.parse(search['timestamp']);
      final isToday = searchDate.year == today.year && 
                     searchDate.month == today.month && 
                     searchDate.day == today.day;

      return ListTile(
        leading: Icon(
          search['type'] == 'text' ? Icons.search : Icons.camera_alt,
          color: Colors.green,
        ),
        title: Text(
          search['query'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isToday 
            ? 'Today at ${DateFormat.jm().format(searchDate)}'
            : DateFormat.yMMMd().add_jm().format(searchDate),
        ),
        onTap: () {
          Navigator.pop(context);
          if (search['type'] == 'text') {
            _textController.text = search['query'];
            _sendTextMessage();
          } else {
            // TODO: Handle image search history tap
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image search history feature coming soon!')),
            );
          }
        },
      );
    }).toList();
  }

  Widget _buildOnlineInfoTab() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Take a photo of your plant or ask me anything about plant health.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  if (message.type == MessageType.image && message.imagePath != null) {
                    return Align(
                      alignment: message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: message.isUserMessage ? Colors.green[200] : Colors.green[800],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(message.imagePath!),
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                }
                    return Align(
                      alignment: message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: message.isUserMessage ? Colors.green[200] : Colors.green[800],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                      message.text ?? '',
                          style: TextStyle(
                        color: message.isUserMessage ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ),
                    );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about your plant',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.green,
                      size: 28,
                    ),
                    onPressed: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                  ),
                  IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.green),
                  onPressed: () => _showImageSourceDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineInfoTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TabBar(
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14,
              ),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: Icon(Icons.apple),
                  text: 'Fruits',
                ),
                Tab(
                  icon: Icon(Icons.eco),
                  text: 'Vegetables',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFruitsList(),
                _buildVegetablesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFruitsList() {
    final List<Map<String, dynamic>> fruits = [
      {
        'name': 'Mango',
        'image': 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=500',
        'growingInfo': '''
How to Grow Mango Trees:

1. Planting:
   - Choose a sunny location with well-draining soil
   - Plant in spring or early summer
   - Dig a hole twice the size of the root ball
   - Space trees 25-30 feet apart

2. Watering:
   - Water deeply once a week
   - Reduce watering in winter
   - Avoid waterlogging

3. Fertilization:
   - Use balanced fertilizer (10-10-10)
   - Apply in spring and summer
   - Avoid fertilizing in winter
   
Recommended Fertilizers:
• NPK 10-10-10 (General purpose)
• Organic compost
• Bone meal for phosphorus
• Epsom salt for magnesium

4. Pruning:
   - Prune after harvest
   - Remove dead or diseased branches
   - Maintain tree height at 15-20 feet

5. Harvesting:
   - Harvest when fruits are slightly soft
   - Color changes from green to yellow/orange
   - Pick carefully to avoid bruising
''',
        'fertilizerLinks': [
          'https://www.amazon.com/s?k=mango+tree+fertilizer',
          'https://www.homedepot.com/s/mango%2520tree%2520fertilizer',
        ],
      },
      {
        'name': 'Apple',
        'image': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=500',
        'growingInfo': '''
How to Grow Apple Trees:

1. Planting:
   - Choose a sunny location with well-draining soil
   - Plant in early spring or fall
   - Dig a hole twice the size of the root ball
   - Space trees 20-25 feet apart

2. Watering:
   - Water deeply once a week
   - Increase frequency during dry spells
   - Reduce watering in winter

3. Fertilization:
   - Use balanced fertilizer (10-10-10)
   - Apply in early spring
   - Add compost annually
   
Recommended Fertilizers:
• NPK 10-10-10 (General purpose)
• Organic compost
• Fish emulsion
• Seaweed extract

4. Pruning:
   - Prune in late winter
   - Remove crossing branches
   - Maintain open center structure

5. Harvesting:
   - Harvest when fruits are firm and colored
   - Twist and lift to pick
   - Store in cool, dark place
''',
        'fertilizerLinks': [
          'https://www.amazon.com/s?k=apple+tree+fertilizer',
          'https://www.homedepot.com/s/apple%2520tree%2520fertilizer',
        ],
      },
      {
        'name': 'Orange',
        'image': 'https://images.unsplash.com/photo-1547514701-42782101795e?w=500',
        'growingInfo': '''
How to Grow Orange Trees:

1. Planting:
   - Choose a sunny, sheltered location
   - Plant in spring or early summer
   - Use well-draining soil
   - Space trees 15-20 feet apart

2. Watering:
   - Water deeply and regularly
   - Keep soil consistently moist
   - Reduce watering in winter

3. Fertilization:
   - Use citrus-specific fertilizer
   - Apply in spring and summer
   - Add micronutrients as needed
   
Recommended Fertilizers:
• Citrus-specific NPK 6-4-6
• Organic compost
• Iron chelate
• Zinc sulfate

4. Pruning:
   - Prune to maintain shape
   - Remove dead wood
   - Thin crowded branches

5. Harvesting:
   - Harvest when fully colored
   - Taste test for sweetness
   - Cut with pruning shears
''',
        'fertilizerLinks': [
          'https://www.amazon.com/s?k=citrus+tree+fertilizer',
          'https://www.homedepot.com/s/citrus%2520tree%2520fertilizer',
        ],
      },
    ];

    return ListView.builder(
      itemCount: fruits.length,
      itemBuilder: (context, index) {
        final fruit = fruits[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showPlantDetails(context, fruit),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fruit['image'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fruit['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view growing guide',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVegetablesList() {
    final List<Map<String, dynamic>> vegetables = [
      {
        'name': 'Tomato',
        'image': 'https://images.unsplash.com/photo-1546094097-246e1cca9f17?w=500',
        'growingInfo': '''
How to Grow Tomatoes:

1. Planting:
   - Start seeds indoors 6-8 weeks before last frost
   - Transplant when soil is warm
   - Space plants 24-36 inches apart
   - Plant in full sun

2. Watering:
   - Water deeply and regularly
   - Keep soil consistently moist
   - Avoid wetting leaves
   - Use drip irrigation if possible

3. Fertilization:
   - Use balanced fertilizer (10-10-10)
   - Apply when planting
   - Side-dress every 2-3 weeks
   - Add calcium to prevent blossom end rot
   
Recommended Fertilizers:
• NPK 10-10-10 (General purpose)
• Organic compost
• Bone meal for calcium
• Fish emulsion

4. Support:
   - Use stakes or cages
   - Tie plants as they grow
   - Prune suckers for indeterminate varieties

5. Harvesting:
   - Pick when fully colored
   - Harvest regularly to encourage production
   - Store at room temperature
''',
        'fertilizerLinks': [
          'https://www.amazon.com/s?k=tomato+fertilizer',
          'https://www.homedepot.com/s/tomato%2520fertilizer',
        ],
      },
      {
        'name': 'Carrot',
        'image': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=500',
        'growingInfo': '''
How to Grow Carrots:

1. Planting:
   - Plant in loose, sandy soil
   - Sow seeds directly in garden
   - Space rows 12-18 inches apart
   - Thin seedlings to 2-3 inches apart

2. Watering:
   - Keep soil consistently moist
   - Water deeply but infrequently
   - Avoid overhead watering
   - Mulch to retain moisture

3. Fertilization:
   - Use low-nitrogen fertilizer
   - Add compost before planting
   - Avoid fresh manure
   - Side-dress with potassium
   
Recommended Fertilizers:
• Low-nitrogen NPK 5-10-10
• Organic compost
• Wood ash for potassium
• Bone meal for phosphorus

4. Care:
   - Weed regularly
   - Thin seedlings when needed
   - Monitor for pests
   - Hill soil around tops

5. Harvesting:
   - Harvest when roots are 1 inch in diameter
   - Loosen soil before pulling
   - Store in cool, humid place
   - Remove tops before storing
''',
        'fertilizerLinks': [
          'https://www.amazon.com/s?k=carrot+fertilizer',
          'https://www.homedepot.com/s/carrot%2520fertilizer',
        ],
      },
      {
        'name': 'Cucumber',
        'image': 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=500',
        'growingInfo': '''
How to Grow Cucumbers:

1. Planting:
   - Start seeds indoors or direct sow
   - Plant after last frost
   - Space plants 36-60 inches apart
   - Use trellis for vertical growth

2. Watering:
   - Water deeply and regularly
   - Keep soil consistently moist
   - Avoid wetting leaves
   - Use drip irrigation

3. Fertilization:
   - Use balanced fertilizer
   - Apply when planting
   - Side-dress every 3-4 weeks
   - Add compost to soil
   
Recommended Fertilizers:
• NPK 10-10-10 (General purpose)
• Organic compost
• Fish emulsion
• Seaweed extract

4. Support:
   - Provide trellis or cage
   - Train vines upward
   - Prune excess growth
   - Monitor for pests

5. Harvesting:
   - Pick when firm and green
   - Harvest regularly
   - Don't let fruits get too large
   - Store in refrigerator
''',
        'fertilizerLinks': [
          'https://www.amazon.com/s?k=cucumber+fertilizer',
          'https://www.homedepot.com/s/cucumber%2520fertilizer',
        ],
      },
    ];

    return ListView.builder(
      itemCount: vegetables.length,
      itemBuilder: (context, index) {
        final vegetable = vegetables[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showPlantDetails(context, vegetable),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      vegetable['image'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vegetable['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view growing guide',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPlantDetails(BuildContext context, Map<String, dynamic> plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  plant['name'],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    plant['image'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 100),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Growing Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        plant['growingInfo'],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended Fertilizers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(plant['fertilizerLinks'] as List<String>).map((link) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _launchURL(link),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  link,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Choose Image Source'),
                            content: const Text('Take a photo or select from gallery'),
                            actions: <Widget>[
                              TextButton.icon(
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                            ],
                          );
                        },
                      );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildCommunityTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Community Forum',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        _buildCommunityCard(
          'Plant Care Tips',
          'Share your experience with plant care and get advice from other farmers.',
          Icons.eco,
          Colors.green,
        ),
        _buildCommunityCard(
          'Market Updates',
          'Stay informed about current market prices and trends.',
          Icons.trending_up,
          Colors.orange,
        ),
        _buildCommunityCard(
          'Success Stories',
          'Read inspiring stories from successful farmers in our community.',
          Icons.star,
          Colors.amber,
        ),
        _buildCommunityCard(
          'Ask Experts',
          'Get your questions answered by agricultural experts.',
          Icons.question_answer,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement create post functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create post feature coming soon!')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Post'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityCard(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Implement navigation to specific community section
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title section coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
} 