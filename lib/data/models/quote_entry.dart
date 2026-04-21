class Quote {
  final String text;
  final String? author;
  final String? category;

  Quote({required this.text, this.author, this.category});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['q'] as String? ?? '',
      author: json['a'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'q': text, 'a': author, 'category': category};
  }
}
