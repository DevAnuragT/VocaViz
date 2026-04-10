/// Represents a single step in a repair procedure.
class RepairStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final String? warning;

  RepairStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    this.warning,
  });

  factory RepairStep.fromJson(Map<String, dynamic> json) {
    return RepairStep(
      stepNumber: json['step'] as int? ?? 0,
      title: json['title'] as String? ?? 'Unknown Step',
      instruction: json['instruction'] as String? ?? '',
      warning: json['warning'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': stepNumber,
      'title': title,
      'instruction': instruction,
      'warning': warning,
    };
  }
}
