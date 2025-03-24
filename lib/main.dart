import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SpeechAssistantPage(),
    );
  }
}

class SpeechAssistantPage extends StatefulWidget {
  const SpeechAssistantPage({super.key});

  @override
  State<SpeechAssistantPage> createState() => _SpeechAssistantPageState();
}

class _SpeechAssistantPageState extends State<SpeechAssistantPage> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _newCardTextController = TextEditingController();
  final TextEditingController _newCardIconController = TextEditingController();
  String selectedLanguage = 'en-US';
  List<String> history = [];
  
  List<Map<String, String>> quickPhrases = [
    {'text': 'Yes', 'icon': '👍'},
    {'text': 'No', 'icon': '👎'},
    {'text': 'Thank you', 'icon': '🙏'},
    {'text': 'Please', 'icon': '✨'},
    {'text': 'Help', 'icon': '🆘'},
    {'text': 'Water', 'icon': '💧'},
    {'text': 'Food', 'icon': '🍽'},
    {'text': 'Bathroom', 'icon': '🚻'},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadData();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage(selectedLanguage);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      quickPhrases = List<Map<String, String>>.from(
        jsonDecode(prefs.getString('customCards') ?? jsonEncode(quickPhrases))
      );
      history = prefs.getStringList('history') ?? [];
      selectedLanguage = prefs.getString('language') ?? 'en-US';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customCards', jsonEncode(quickPhrases));
    await prefs.setStringList('history', history);
    await prefs.setString('language', selectedLanguage);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
    setState(() {
      if (!history.contains(text)) {
        history.insert(0, text);
        if (history.length > 20) history.removeLast(); // Keep last 20 items
        _saveData();
      }
    });
  }

  void _addCustomCard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newCardTextController,
              decoration: const InputDecoration(labelText: 'Text'),
            ),
            TextField(
              controller: _newCardIconController,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                quickPhrases.add({
                  'text': _newCardTextController.text,
                  'icon': _newCardIconController.text,
                });
                _saveData();
              });
              Navigator.pop(context);
              _newCardTextController.clear();
              _newCardIconController.clear();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Assistant'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String language) {
              setState(() {
                selectedLanguage = language;
                _initTts();
                _saveData();
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'en-US', child: Text('English')),
              const PopupMenuItem(value: 'si-LK', child: Text('සිංහල')),
              const PopupMenuItem(value: 'ta-LK', child: Text('தமிழ்')),
              const PopupMenuItem(value: 'es-ES', child: Text('Spanish')),
              const PopupMenuItem(value: 'fr-FR', child: Text('French')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Quick Phrases'),
                      Tab(text: 'History'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: quickPhrases.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: InkWell(
                                onTap: () => _speak(quickPhrases[index]['text']!),
                                onLongPress: () {
                                  if (index >= 8) { // Only allow deleting custom cards
                                    setState(() {
                                      quickPhrases.removeAt(index);
                                      _saveData();
                                    });
                                  }
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      quickPhrases[index]['icon']!,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      quickPhrases[index]['text']!,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(history[index]),
                              trailing: IconButton(
                                icon: const Icon(Icons.volume_up),
                                onPressed: () => _speak(history[index]),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type something to say...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _speak(_textController.text);
                    }
                  },
                  child: const Icon(Icons.volume_up),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomCard,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _textController.dispose();
    _newCardTextController.dispose();
    _newCardIconController.dispose();
    super.dispose();
  }
}
