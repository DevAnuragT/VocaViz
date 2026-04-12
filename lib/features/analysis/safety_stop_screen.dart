import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/analysis_result.dart';

/// Dedicated stop screen for low-confidence or technician-required outcomes.
class SafetyStopScreen extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback onHome;
  final VoidCallback onRetry;

  const SafetyStopScreen({
    super.key,
    required this.result,
    required this.onHome,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isLowConfidence = result.isLowConfidence;
    final title = isLowConfidence ? 'Need a clearer image' : 'Technician recommended';
    final subtitle = isLowConfidence
        ? 'VocaViz could not identify the belt issue reliably.'
        : 'The app cannot safely guide this repair from the current inspection.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Stop'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  size: 44,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What the app saw',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.summary,
                        style: const TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Confidence: ${(result.confidence * 100).toInt()}%',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
              if (result.stopConditions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stop conditions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...result.stopConditions.map(
                          (condition) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                Expanded(child: Text(condition)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(isLowConfidence ? 'Retake Inspection' : 'Start New Inspection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
