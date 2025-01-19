class PhraseCategory {
  final String name;
  final String icon;
  final List<Map<String, String>> phrases;

  const PhraseCategory({
    required this.name,
    required this.icon,
    required this.phrases,
  });
}

final List<PhraseCategory> defaultCategories = [
  PhraseCategory(
    name: 'Basic',
    icon: '💬',
    phrases: [
      {'text': 'Yes', 'icon': '👍'},
      {'text': 'No', 'icon': '👎'},
      {'text': 'Thank you', 'icon': '🙏'},
      {'text': 'Please', 'icon': '✨'},
      {'text': 'Help', 'icon': '🆘'},
    ],
  ),
  PhraseCategory(
    name: 'Food & Drink',
    icon: '🍽',
    phrases: [
      {'text': 'I am hungry', 'icon': '😋'},
      {'text': 'Water please', 'icon': '💧'},
      {'text': 'Coffee', 'icon': '☕'},
      {'text': 'Food', 'icon': '🍲'},
      {'text': 'Check please', 'icon': '💳'},
    ],
  ),
  PhraseCategory(
    name: 'Navigation',
    icon: '🗺',
    phrases: [
      {'text': 'Where is bathroom?', 'icon': '🚻'},
      {'text': 'I am lost', 'icon': '😕'},
      {'text': 'Call taxi', 'icon': '🚕'},
      {'text': 'Bus station', 'icon': '🚌'},
      {'text': 'Hospital', 'icon': '🏥'},
    ],
  ),
  PhraseCategory(
    name: 'Shopping',
    icon: '🛍',
    phrases: [
      {'text': 'How much?', 'icon': '💰'},
      {'text': 'Too expensive', 'icon': '😮'},
      {'text': 'Discount?', 'icon': '🏷'},
      {'text': 'I will buy', 'icon': '✅'},
      {'text': 'Payment method?', 'icon': '💳'},
    ],
  ),
];
