class InstructionMaterial {
  final String title;
  final String description;

  InstructionMaterial({required this.title, required this.description});

  factory InstructionMaterial.fromJson(Map<String, dynamic> json) {
    return InstructionMaterial(
      title: json['title'],
      description: json['description'],
    );
  }

  Map<String, String> toMap() => {
        'title': title,
        'description': description,
      };
}
