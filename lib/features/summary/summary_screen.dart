import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/analysis_result.dart';

/// Session summary screen shown after repair completion.
class SummaryScreen extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback onHome;
  final VoidCallback onNewInspection;

  const SummaryScreen({
    super.key,
    required this.result,
    required this.onHome,
    required this.onNewInspection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.success,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Inspection Complete',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Issue identified
              Text(
                'Identified: ${result.issueType.replaceAll('_', ' ')}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.summary,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stats card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Confidence',
                        value: '${(result.confidence * 100).toInt()}%',
                        icon: Icons.verified,
                        color: AppColors.primary,
                      ),
                      _StatItem(
                        label: 'Detections',
                        value: result.detections.length.toString(),
                        icon: Icons.visibility,
                        color: AppColors.warning,
                      ),
                      _StatItem(
                        label: 'Steps',
                        value: result.repairSteps.length.toString(),
                        icon: Icons.build,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNewInspection,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('New Inspection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
