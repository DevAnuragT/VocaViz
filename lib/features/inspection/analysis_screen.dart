import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/overlay_painter.dart';
import '../../core/widgets/model_status_widget.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/detection.dart';
import '../../core/utils/env_config.dart';
import '../../services/inference_service.dart';
import 'providers/analysis_controller.dart';

/// Screen that shows analysis in progress and displays results.
class AnalysisScreen extends ConsumerStatefulWidget {
  final Uint8List imageBytes;
  final String source; // 'camera', 'gallery', 'sample'
  final String? scenario; // For mock mode - which fault to simulate
  final VoidCallback onBack;
  final Function(AnalysisResult result) onAnalysisComplete;
  final VoidCallback onStartRepair;

  const AnalysisScreen({
    super.key,
    required this.imageBytes,
    required this.source,
    this.scenario,
    required this.onBack,
    required this.onAnalysisComplete,
    required this.onStartRepair,
  });

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  String _modeLabel() {
    if (EnvConfig.isOfflineMode) return 'offline';
    if (EnvConfig.isRemoteMode) return 'Gemma AI';
    if (EnvConfig.isLocalMode) return 'local';
    return 'mock';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysis();
    });
  }

  @override
  void didUpdateWidget(covariant AnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes || oldWidget.scenario != widget.scenario) {
      _runAnalysis();
    }
  }

  void _runAnalysis() {
    ref.read(analysisControllerProvider.notifier).analyze(
        imageBytes: widget.imageBytes,
        scenario: widget.scenario,
      );
  }

  void _showModelStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Model Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              ModelStatusWidget(
                inferenceService: InferenceService(),
                onModelReady: () {
                  debugPrint('Model ready - can now use local mode');
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Current mode: ${EnvConfig.mode}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (EnvConfig.isRemoteMode)
                Text(
                  'Model: ${EnvConfig.model}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AnalysisState>(analysisControllerProvider, (previous, next) {
      if (next.result != null && previous?.result != next.result) {
        widget.onAnalysisComplete(next.result!);
      }
    });

    final state = ref.watch(analysisControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.isAnalyzing ? null : widget.onBack,
        ),
        actions: [
          if (!state.isAnalyzing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runAnalysis,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showModelStatusDialog(context),
            tooltip: 'Model Status',
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview with overlay
          Expanded(
            flex: 2,
            child: _buildImageSection(state),
          ),

          // Results section
          Expanded(
            flex: 3,
            child: _buildResultsSection(state),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(AnalysisState state) {
    if (state.isAnalyzing) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Blurred image preview
              Opacity(
                opacity: 0.3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AnalysisLoadingIndicator(
                message: 'Analyzing image...',
                subMessage: 'Identifying belt condition',
              ),
            ],
          ),
        ),
      );
    }

    // Show image with overlay if we have detections
    return Container(
      color: Colors.black,
      child: Center(
        child: state.result != null && state.result!.detections.isNotEmpty
            ? DetectionOverlay(
                detections: state.result!.detections,
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                ),
              )
            : Image.memory(
                widget.imageBytes,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Widget _buildResultsSection(AnalysisState state) {
    if (state.isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
              Text(
                'Processing with ${_modeLabel()} inference...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.result == null) {
      return const Center(child: Text('No result'));
    }

    return _buildResultContent(state.result!);
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Analysis Failed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _runAnalysis,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(AnalysisResult result) {
    final isLowConfidence = result.isLowConfidence;
    final requiresTech = result.requiresTechnician;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence badge
          Row(
            children: [
              _buildConfidenceBadge(result.confidence),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.issueType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary
          Text(
            result.summary,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Warning if low confidence or needs technician
          if (isLowConfidence || requiresTech) ...[
            _buildWarningCard(isLowConfidence),
            const SizedBox(height: 24),
          ],

          // Detections summary
          if (result.detections.isNotEmpty) ...[
            const Text(
              'Detected Regions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...result.detections.map((d) => _buildDetectionChip(d)),
            const SizedBox(height: 24),
          ],

          // Action button
          if (!isLowConfidence && !requiresTech)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onStartRepair,
                icon: const Icon(Icons.build),
                label: const Text('Start Repair Guide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Home'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    Color color;

    if (confidence >= AppConstants.highConfidenceThreshold) {
      color = AppColors.success;
    } else if (confidence >= AppConstants.mediumConfidenceThreshold) {
      color = AppColors.warning;
    } else {
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(bool isLowConfidence) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caution Required',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLowConfidence
                        ? 'Analysis confidence is low. Verify findings before proceeding.'
                        : 'This issue may require professional assistance.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionChip(Detection detection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _severityColor(detection.severity),
            shape: BoxShape.circle,
          ),
        ),
        label: Text(
          detection.label.replaceAll('_', ' '),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        side: BorderSide(color: _severityColor(detection.severity)),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return AppColors.severityHigh;
      case 'medium':
        return AppColors.severityMedium;
      default:
        return AppColors.severityLow;
    }
  }
}
