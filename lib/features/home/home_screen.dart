import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/device_capabilities.dart';
import '../../core/utils/env_config.dart';
import '../../core/utils/preferences.dart';

/// Home screen - main entry point with action buttons.
class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMode = EnvConfig.mode;
  bool _supportsLocal = false;
  bool _modeLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModeSettings();
  }

  Future<void> _loadModeSettings() async {
    final preferred = await AppPreferences.getInferenceMode();
    final supportsLocal = await DeviceCapabilities.supportsLocalGemma();
    final mode = preferred ?? EnvConfig.mode;
    final safeMode = (!supportsLocal && mode == 'local') ? 'offline' : mode;

    if (safeMode != mode) {
      await AppPreferences.setInferenceMode(safeMode);
      EnvConfig.setOverrideMode(safeMode);
    }

    if (mounted) {
      setState(() {
        _selectedMode = safeMode;
        _supportsLocal = supportsLocal;
        _modeLoading = false;
      });
    }
  }

  Future<void> _setMode(String mode) async {
    if (mode == 'local' && !_supportsLocal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local Gemma requires 8 GB+ RAM. Using offline mode.'),
        ),
      );
      return;
    }

    await AppPreferences.setInferenceMode(mode);
    EnvConfig.setOverrideMode(mode);
    if (mounted) {
      setState(() => _selectedMode = mode);
    }
  }

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

              _buildModeSelector(),
              const SizedBox(height: 24),

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
        onTap: widget.onInspectPressed,
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
                      onPressed: widget.onInspectPressed,
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

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600]),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supported: Belt-driven water pumps',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Detects: Loose belt, worn belt, misalignment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryActionCard(
            icon: Icons.photo_library_outlined,
            title: 'Sample Images',
            subtitle: 'Try demo images',
            onTap: widget.onSampleImagesPressed,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        if (widget.onHistoryPressed != null)
          Expanded(
            child: _SecondaryActionCard(
              icon: Icons.history,
              title: 'History',
              subtitle: 'Recent inspections',
              onTap: widget.onHistoryPressed!,
              color: AppColors.info,
            ),
          ),
      ],
    );
  }
  Widget _buildModeSelector() {
    if (_modeLoading) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inference Mode',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                _modeItem('offline', 'Offline (pre-generated Gemma) - recommended'),
                _modeItem('remote', 'Remote (Gemma API) - requires internet'),
                _modeItem(
                  'local',
                  _supportsLocal
                      ? 'Local (on-device Gemma) - high-end only'
                      : 'Local (on-device Gemma) - requires 8 GB+ RAM',
                ),
                _modeItem('mock', 'Mock (demo mode)'),
              ],
              onChanged: (value) {
                if (value == null) return;
                _setMode(value);
              },
            ),
            if (!_supportsLocal)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Local mode disabled on low-RAM devices.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _modeItem(String value, String label) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(label),
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
