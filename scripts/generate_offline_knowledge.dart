import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

const _outputPath = 'assets/knowledge/offline_knowledge_base.json';

const _issues = <String, String>{
  'loose_belt': 'Belt sag and low tension between pulleys',
  'worn_belt': 'Cracks, fraying, glazing, or visible wear on belt surface',
  'misaligned_belt': 'Belt tracking off-center or not aligned on pulleys',
};

Future<void> main(List<String> args) async {
  final parsedArgs = _parseArgs(args);
  final env = await _loadEnvFile('.env');
  final apiKey = Platform.environment['GEMMA_API_KEY'] ?? env['GEMMA_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('GEMMA_API_KEY is required.');
    exit(1);
  }

  final modelName =
      parsedArgs['model'] ?? Platform.environment['GEMMA_MODEL'] ?? env['GEMMA_MODEL'] ?? 'gemma-4-31b-it';
  final model = GenerativeModel(
    model: modelName,
    apiKey: apiKey,
  );

  final results = <String, dynamic>{};

  for (final entry in _issues.entries) {
    final issueType = entry.key;
    final description = entry.value;
    stdout.writeln('Generating knowledge for $issueType...');

    final prompt = _buildPrompt(issueType, description);
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();

    if (text == null || text.isEmpty) {
      stderr.writeln('Empty response for $issueType');
      exit(1);
    }

    final jsonObject = _extractJson(text);
    results[issueType] = jsonObject;
  }

  final output = const JsonEncoder.withIndent('  ').convert(results);
  await File(_outputPath).writeAsString(output);
  stdout.writeln('Wrote offline knowledge to $_outputPath');
  stdout.writeln('Model used: $modelName');
}

Map<String, String> _parseArgs(List<String> args) {
  final values = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--') || !arg.contains('=')) continue;
    final index = arg.indexOf('=');
    final key = arg.substring(2, index);
    final value = arg.substring(index + 1);
    values[key] = value;
  }
  return values;
}

Future<Map<String, String>> _loadEnvFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    return {};
  }

  final values = <String, String>{};
  for (final line in await file.readAsLines()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#') || !trimmed.contains('=')) {
      continue;
    }

    final index = trimmed.indexOf('=');
    final key = trimmed.substring(0, index).trim();
    final value = trimmed.substring(index + 1).trim();
    values[key] = value;
  }

  return values;
}

String _buildPrompt(String issueType, String description) {
  return '''You are an expert agricultural equipment inspector.
Generate a single JSON object for the fault type "$issueType".

Context: $description

Return ONLY JSON with this exact schema and keys:
{
  "machine_type": "belt_driven_water_pump",
  "issue_type": "$issueType",
  "confidence": 0.0-1.0,
  "summary": "short description",
  "detections": [
    {"label":"belt|pulley|worn_area|sag_zone|misalignment_zone", "x":0-1, "y":0-1, "width":0-1, "height":0-1, "severity":"low|medium|high"}
  ],
  "repair_steps": [
    {"step":1, "title":"...", "instruction":"...", "warning": null|"..."}
  ],
  "stop_conditions": ["..."]
}

Rules:
- Use 3-6 repair steps.
- Use 1-3 detections, normalized 0-1.
- Keep summary under 200 chars.
- No markdown, no extra keys, no commentary.
''';
}

Map<String, dynamic> _extractJson(String text) {
  final trimmed = text.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    throw FormatException('No JSON object found.');
  }
  final candidate = trimmed.substring(start, end + 1);
  final decoded = jsonDecode(candidate);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  throw FormatException('Decoded response was not a JSON object.');
}
