class Document {
  final String title;
  final String status;

  Document({
    required this.title,
    required this.status,
  });

  Map<String, String> toMap() {
    return {
      'title': title,
      'status': status,
    };
  }
}