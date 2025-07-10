class InstructionStep {
  final String title;
  final String description;

  InstructionStep({required this.title, required this.description});

  factory InstructionStep.fromJson(Map<String, dynamic> json) {
    return InstructionStep(
      title: json['title'],
      description: json['description'],
    );
  }

  Map<String, String> toMap() => {
        'title': title,
        'description': description,
      };
}
