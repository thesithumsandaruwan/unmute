class CustomCard {
  final String text;
  final String icon;
  final DateTime createdAt;

  CustomCard({
    required this.text,
    required this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CustomCard.fromJson(Map<String, dynamic> json) => CustomCard(
    text: json['text'],
    icon: json['icon'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
