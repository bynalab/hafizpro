class TranslationInfo {
  final String id;
  final String name;
  final String language;
  final String type;

  const TranslationInfo({
    required this.id,
    required this.name,
    required this.language,
    required this.type,
  });

  factory TranslationInfo.fromMap(Map<String, dynamic> map) {
    return TranslationInfo(
      id: map['id'] as String,
      name: map['name'] as String,
      language: map['language'] as String,
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'language': language,
      'type': type,
    };
  }
}
