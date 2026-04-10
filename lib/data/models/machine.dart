/// Represents a known machine type with associated repair knowledge.
class Machine {
  final String id;
  final String name;
  final String description;
  final List<String> knownIssues;

  const Machine({
    required this.id,
    required this.name,
    required this.description,
    required this.knownIssues,
  });

  /// Belt-driven water pump - our primary supported machine
  static const beltDrivenPump = Machine(
    id: 'belt_driven_water_pump',
    name: 'Belt-Driven Water Pump',
    description: 'Agricultural/irrigation water pump with belt drive system',
    knownIssues: ['loose_belt', 'worn_belt', 'misaligned_belt'],
  );

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unknown Machine',
      description: json['description'] as String? ?? '',
      knownIssues: List<String>.from(json['known_issues'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'known_issues': knownIssues,
    };
  }
}
