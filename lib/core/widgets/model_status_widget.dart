import 'package:flutter/material.dart';
import '../../services/inference_service.dart';

/// Widget that displays the local Gemma 4 model status.
/// Shows appropriate UI based on model availability.
class ModelStatusWidget extends StatefulWidget {
  final InferenceService inferenceService;
  final VoidCallback? onModelReady;

  const ModelStatusWidget({
    super.key,
    required this.inferenceService,
    this.onModelReady,
  });

  @override
  State<ModelStatusWidget> createState() => _ModelStatusWidgetState();
}

class _ModelStatusWidgetState extends State<ModelStatusWidget> {
  LocalModelStatus _status = LocalModelStatus.notInitialized;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkModelStatus();
    });
  }

  Future<void> _checkModelStatus() async {
    setState(() => _isLoading = true);

    try {
      final status = await widget.inferenceService.checkLocalModelAvailability();
      setState(() {
        _status = status;
        _error = widget.inferenceService.localModelError?.toString();
        _isLoading = false;
      });

      if (status == LocalModelStatus.ready) {
        widget.onModelReady?.call();
      }
    } catch (e) {
      setState(() {
        _status = LocalModelStatus.initFailed;
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDescription(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null && _error!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red.shade700,
                ),
              ),
            ],
            if (_status == LocalModelStatus.artifactMissing) ...[
              const SizedBox(height: 12),
              _buildSetupButton(),
            ],
            if (_status == LocalModelStatus.notInitialized ||
                _status == LocalModelStatus.initFailed) ...[
              const SizedBox(height: 12),
              _buildRetryButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Checking Gemma 4 model...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (_status) {
      case LocalModelStatus.ready:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case LocalModelStatus.loading:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case LocalModelStatus.artifactMissing:
        icon = Icons.folder_off;
        color = Colors.red;
        break;
      case LocalModelStatus.artifactIncompatible:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case LocalModelStatus.deviceInsufficient:
        icon = Icons.memory;
        color = Colors.red;
        break;
      case LocalModelStatus.initFailed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case LocalModelStatus.notInitialized:
        icon = Icons.help_outline;
        color = Colors.grey;
        break;
    }

    return Icon(icon, color: color, size: 28);
  }

  String _getTitle() {
    switch (_status) {
      case LocalModelStatus.ready:
        return 'Gemma 4 Ready';
      case LocalModelStatus.loading:
        return 'Loading Model...';
      case LocalModelStatus.artifactMissing:
        return 'Model Not Installed';
      case LocalModelStatus.artifactIncompatible:
        return 'Model Format Incompatible';
      case LocalModelStatus.deviceInsufficient:
        return 'Device Resources Insufficient';
      case LocalModelStatus.initFailed:
        return 'Model Init Failed';
      case LocalModelStatus.notInitialized:
        return 'Model Status Unknown';
    }
  }

  String _getDescription() {
    switch (_status) {
      case LocalModelStatus.ready:
        return 'On-device Gemma 4 is ready for offline inference';
      case LocalModelStatus.loading:
        return 'Please wait while we check model availability';
      case LocalModelStatus.artifactMissing:
        return 'Place gemma-4-2b.task in assets/models/ to enable offline AI';
      case LocalModelStatus.artifactIncompatible:
        return 'Model must be in .task or .tflite format';
      case LocalModelStatus.deviceInsufficient:
        return 'Device lacks RAM or NPU support for local inference';
      case LocalModelStatus.initFailed:
        return 'Check logs for details. You can retry initialization.';
      case LocalModelStatus.notInitialized:
        return 'Tap refresh to check model availability';
    }
  }

  Widget _buildSetupButton() {
    return OutlinedButton.icon(
      onPressed: () {
        // Show setup instructions dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Setup Gemma 4 Local Inference'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('To enable on-device Gemma 4:'),
                  const SizedBox(height: 16),
                  _buildStep('1', 'Download Gemma 4 model artifact'),
                  _buildStep('2', 'Place file at: assets/models/gemma-4-2b.task'),
                  _buildStep('3', 'Run: flutter pub get'),
                  _buildStep('4', 'Rebuild and run the app'),
                  const SizedBox(height: 16),
                  const Text(
                    'See GEMMA4_MODEL_SETUP.md for detailed instructions.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.settings),
      label: const Text('Setup Instructions'),
    );
  }

  Widget _buildRetryButton() {
    return TextButton.icon(
      onPressed: _checkModelStatus,
      icon: const Icon(Icons.refresh),
      label: const Text('Check Again'),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                (Theme.of(context).primaryColor.r * 255).toInt(),
                (Theme.of(context).primaryColor.g * 255).toInt(),
                (Theme.of(context).primaryColor.b * 255).toInt(),
                0.2,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}
