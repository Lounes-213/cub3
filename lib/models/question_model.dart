class QuestionModel {
  final String? id;
  final String category;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String hint1;
  final String hint2;
  final String hint3;

  const QuestionModel({
    this.id,
    required this.category,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.hint1 = '',
    this.hint2 = '',
    this.hint3 = '',
  });

  factory QuestionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return QuestionModel(
      id: id,
      category: map['category'] ?? '',
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      explanation: map['explanation'] ?? '',
      hint1: map['hint1'] ?? '',
      hint2: map['hint2'] ?? '',
      hint3: map['hint3'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'questionText': questionText,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'hint1': hint1,
    'hint2': hint2,
    'hint3': hint3,
  };

  QuestionModel copyWith({
    String? id,
    String? category,
    String? questionText,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? hint1,
    String? hint2,
    String? hint3,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      category: category ?? this.category,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      hint1: hint1 ?? this.hint1,
      hint2: hint2 ?? this.hint2,
      hint3: hint3 ?? this.hint3,
    );
  }
}
