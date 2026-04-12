import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/mock/mock_knowledge_base.dart';

/// Screen showing sample images for demo purposes.
class SampleImagesScreen extends StatelessWidget {
  final Function(String scenario) onImageSelected;
  final VoidCallback? onBack;

  const SampleImagesScreen({
    super.key,
    required this.onImageSelected,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Images'),
        leading: onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select a sample image to see how VocaViz detects different belt issues:',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _SampleCard(
                    title: 'Loose Belt',
                    description: 'Excessive belt sag',
                    icon: Icons.remove,
                    color: AppColors.warning,
                    scenario: 'loose_belt',
                    onTap: () => onImageSelected('loose_belt'),
                  ),
                  _SampleCard(
                    title: 'Worn Belt',
                    description: 'Cracks and wear',
                    icon: Icons.broken_image,
                    color: AppColors.error,
                    scenario: 'worn_belt',
                    onTap: () => onImageSelected('worn_belt'),
                  ),
                  _SampleCard(
                    title: 'Misaligned Belt',
                    description: 'Off-center tracking',
                    icon: Icons.swap_horiz,
                    color: AppColors.info,
                    scenario: 'misaligned_belt',
                    onTap: () => onImageSelected('misaligned_belt'),
                  ),
                ],
              ),
            ),

            // Info footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'In production, these would be real photos from your camera',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String scenario;
  final VoidCallback onTap;

  const _SampleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.scenario,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = MockKnowledgeBase.sampleImages[scenario];

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 84,
                  child: imagePath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _SamplePlaceholder(icon: icon, color: color);
                              },
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _SamplePlaceholder(icon: icon, color: color),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to analyze',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SamplePlaceholder extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SamplePlaceholder({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}
