import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Home screen - main entry point with action buttons.
class HomeScreen extends StatelessWidget {
  final VoidCallback onInspectPressed;
  final VoidCallback onSampleImagesPressed;
  final VoidCallback? onHistoryPressed;

  const HomeScreen({
    super.key,
    required this.onInspectPressed,
    required this.onSampleImagesPressed,
    this.onHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _buildWelcomeSection(),
              const SizedBox(height: 32),

              // Main action card
              _buildMainActionCard(context),
              const SizedBox(height: 24),

              // Secondary actions
              _buildSecondaryActions(context),
              const SizedBox(height: 24),

              // Info card
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ready to inspect?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Identify belt issues and get repair guidance',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionCard(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onInspectPressed,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Inspection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use camera to analyze a water pump',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onInspectPressed,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Open Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryActionCard(
            icon: Icons.photo_library_outlined,
            title: 'Sample Images',
            subtitle: 'Try demo images',
            onTap: onSampleImagesPressed,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        if (onHistoryPressed != null)
          Expanded(
            child: _SecondaryActionCard(
              icon: Icons.history,
              title: 'History',
              subtitle: 'Recent inspections',
              onTap: onHistoryPressed!,
              color: AppColors.info,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supported: Belt-driven water pumps',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Detects: Loose belt, worn belt, misalignment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _SecondaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
