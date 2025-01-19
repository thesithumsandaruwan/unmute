import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unmute/models/custom_card.dart';
import 'package:unmute/models/phrase_category.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:unmute/theme/app_theme.dart';
import 'package:unmute/widgets/custom_card_dialog.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

void main() {
  // Add these lines before runApp
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Assistant',
      theme: AppTheme.lightTheme,
      home: const SpeechAssistantPage(),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class SpeechAssistantPage extends StatefulWidget {
  const SpeechAssistantPage({super.key});

  @override
  State<SpeechAssistantPage> createState() => _SpeechAssistantPageState();
}

class _SpeechAssistantPageState extends State<SpeechAssistantPage> with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _newCardTextController = TextEditingController();
  final TextEditingController _newCardIconController = TextEditingController();
  String selectedLanguage = 'en-US';
  List<String> history = [];
  List<Map<String, String>> quickPhrases = [];
  List<PhraseCategory> categories = defaultCategories;
  double speechRate = 0.5;
  double pitch = 1.0;
  List<dynamic>? voices;
  String? selectedVoice;
  late TabController _tabController;
  List<CustomCard> myCards = [];
  int _currentIndex = 1; // Start with My Cards tab

  @override
  void initState() {
    super.initState();
    // Optimize animations
    timeDilation = 0.9;
    _tabController = TabController(length: categories.length + 1, vsync: this);
    _initTts();
    _loadData();
  }

  Future<void> _initTts() async {
    voices = await flutterTts.getVoices;
    await flutterTts.setLanguage(selectedLanguage);
    await flutterTts.setSpeechRate(speechRate);
    await flutterTts.setPitch(pitch);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      history = prefs.getStringList('history') ?? [];
      selectedLanguage = prefs.getString('language') ?? 'en-US';
      speechRate = prefs.getDouble('speechRate') ?? 0.5;
      pitch = prefs.getDouble('pitch') ?? 1.0;
      selectedVoice = prefs.getString('voice');
      final cardsJson = prefs.getStringList('myCards') ?? [];
      myCards = cardsJson
          .map((json) => CustomCard.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', history);
    await prefs.setString('language', selectedLanguage);
    await prefs.setDouble('speechRate', speechRate);
    await prefs.setDouble('pitch', pitch);
    if (selectedVoice != null) {
      await prefs.setString('voice', selectedVoice!);
    }
    await prefs.setStringList(
      'myCards',
      myCards.map((card) => jsonEncode(card.toJson())).toList(),
    );
  }

  void _showVoiceSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Voice Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Speech Rate: ${speechRate.toStringAsFixed(2)}'),
              Slider(
                value: speechRate,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  setState(() => speechRate = value);
                  flutterTts.setSpeechRate(value);
                  _saveData();
                },
              ),
              Text('Pitch: ${pitch.toStringAsFixed(2)}'),
              Slider(
                value: pitch,
                min: 0.5,
                max: 2.0,
                onChanged: (value) {
                  setState(() => pitch = value);
                  flutterTts.setPitch(value);
                  _saveData();
                },
              ),
              if (voices != null) ...[
                const Text('Voice:'),
                DropdownButton<String>(
                  value: selectedVoice,
                  isExpanded: true,
                  items: voices!
                      .map((voice) => DropdownMenuItem(
                            value: voice['name'].toString(),
                            child: Text(voice['name'].toString()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedVoice = value);
                      flutterTts.setVoice({"name": value, "locale": selectedLanguage});
                      _saveData();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildCategoriesView(),
          _buildMyCardsView(),
          _buildHistoryView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: AppTheme.glassEffect,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'My Cards',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesView() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Categories'),
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_voice),
                  onPressed: () => _showVoiceSettings(),
                ),
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () => _showLanguageSelector(),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 16, right: 16, top: 16, bottom: 100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ...categories.map((category) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: category.phrases.length,
                        itemBuilder: (context, index) => _buildCard(
                          category.phrases[index],
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.cardGradients[categories.indexOf(category)],
                              AppTheme.cardGradients[categories.indexOf(category)].withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  )).toList(),
                ]),
              ),
            ),
          ],
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            decoration: AppTheme.glassEffect,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type something to say...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onChanged: (_) => HapticFeedback.selectionClick(),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'speak',
                      onPressed: () {
                        if (_textController.text.isNotEmpty) {
                          HapticFeedback.mediumImpact();
                          _speak(_textController.text);
                          _textController.clear();
                        }
                      },
                      child: const Icon(Icons.volume_up),
                    ).animate()
                      .scale(delay: const Duration(milliseconds: 200)),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'add',
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _addCustomCard();
                      },
                      child: const Icon(Icons.add),
                    ).animate()
                      .scale(delay: const Duration(milliseconds: 300)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyCardsView() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('My Cards'),
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_voice),
                  onPressed: () => _showVoiceSettings(),
                ),
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () => _showLanguageSelector(),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCard(
                    {'text': myCards[index].text, 'icon': myCards[index].icon},
                    gradient: LinearGradient(
                      colors: [AppTheme.cardGradients[index % AppTheme.cardGradients.length], AppTheme.cardGradients[index % AppTheme.cardGradients.length].withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  childCount: myCards.length,
                ),
              ),
            ),
          ],
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHistoryView() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('History'),
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_voice),
                  onPressed: () => _showVoiceSettings(),
                ),
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () => _showLanguageSelector(),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(history[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _speak(history[index]);
                        },
                      ),
                    ),
                  ).animate()
                    .fade(delay: Duration(milliseconds: index * 50))
                    .slideX(),
                  childCount: history.length,
                ),
              ),
            ),
          ],
        ),
        _buildInputArea(),
      ],
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: AppTheme.glassEffect,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildLanguageOption('en-US', 'English'),
              _buildLanguageOption('si-LK', 'සිංහල'),
              _buildLanguageOption('ta-LK', 'தமிழ்'),
              _buildLanguageOption('es-ES', 'Español'),
              _buildLanguageOption('fr-FR', 'Français'),
              _buildLanguageOption('de-DE', 'Deutsch'),
              _buildLanguageOption('it-IT', 'Italiano'),
              _buildLanguageOption('ja-JP', '日本語'),
              _buildLanguageOption('ko-KR', '한국어'),
              _buildLanguageOption('zh-CN', '中文'),
            ],
          ),
        ),
      ),
    );
  }

  ListTile _buildLanguageOption(String code, String name) {
    return ListTile(
      title: Text(name),
      trailing: selectedLanguage == code ? const Icon(Icons.check) : null,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          selectedLanguage = code;
          _initTts();
          _saveData();
        });
        Navigator.pop(context);
      },
    );
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
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => CustomCardDialog(
        onAdd: (text, icon) {
          setState(() {
            final newCard = CustomCard(
              text: text,
              icon: icon,
            );
            myCards.add(newCard);
            _saveData();
          });
        },
      ),
    );
  }

  Widget _buildCard(Map<String, String> phrase, {Gradient? gradient}) {
    return Card(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _speak(phrase['text']!);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassEffect,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                phrase['icon']!,
                style: const TextStyle(fontSize: 32),
              ).animate()
                .fade(duration: const Duration(milliseconds: 300))
                .scale(delay: const Duration(milliseconds: 100)),
              const SizedBox(height: 8),
              Text(
                phrase['text']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fade(duration: const Duration(milliseconds: 300))
                .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    ).animate()
      .fade(duration: const Duration(milliseconds: 400))
      .scale(begin: const Offset(0.8, 0.8));
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
