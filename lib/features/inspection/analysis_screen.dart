import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/overlay_painter.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/detection.dart';
import '../../services/inference_service.dart';
import '../../core/utils/logger.dart';

/// Screen that shows analysis in progress and displays results.
class AnalysisScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String source; // 'camera', 'gallery', 'sample'
  final String? scenario; // For mock mode - which fault to simulate
  final VoidCallback onBack;
  final Function(AnalysisResult result) onAnalysisComplete;

  const AnalysisScreen({
    super.key,
    required this.imageBytes,
    required this.source,
    this.scenario,
    required this.onBack,
    required this.onAnalysisComplete,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final InferenceService _inferenceService = InferenceService();

  bool _isAnalyzing = true;
  AnalysisResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      setState(() {
        _isAnalyzing = true;
        _error = null;
      });

      // Always use mock mode for reliability during hackathon
      _inferenceService.mode = InferenceMode.mock;

      final result = await _inferenceService.analyze(
        imageBytes: widget.imageBytes,
        scenario: widget.scenario,
      );

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _result = result;
      });

      // Notify parent of result
      widget.onAnalysisComplete(result);
    } catch (e) {
      AppLogger.e('Analysis failed', 'AnalysisScreen', e);

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _error = 'Analysis failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isAnalyzing ? null : widget.onBack,
        ),
        actions: [
          if (!_isAnalyzing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runAnalysis,
            ),
        ],
      ),
      body: Column(
        children: [
          // Image preview with overlay
          Expanded(
            flex: 2,
            child: _buildImageSection(),
          ),

          // Results section
          Expanded(
            flex: 3,
            child: _buildResultsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (_isAnalyzing) {
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
        child: _result != null && _result!.detections.isNotEmpty
            ? DetectionOverlay(
                detections: _result!.detections,
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

  Widget _buildResultsSection() {
    if (_isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Processing with ${InferenceMode.mock} inference...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_result == null) {
      return const Center(child: Text('No result'));
    }

    return _buildResultContent();
  }

  Widget _buildErrorState() {
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
            _error!,
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

  Widget _buildResultContent() {
    final isLowConfidence = _result!.isLowConfidence;
    final requiresTech = _result!.requiresTechnician;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence badge
          Row(
            children: [
              _buildConfidenceBadge(_result!.confidence),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _result!.issueType.replaceAll('_', ' ').toUpperCase(),
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
            _result!.summary,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Warning if low confidence or needs technician
          if (isLowConfidence || requiresTech) ...[
            _buildWarningCard(),
            const SizedBox(height: 24),
          ],

          // Detections summary
          if (_result!.detections.isNotEmpty) ...[
            const Text(
              'Detected Regions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._result!.detections.map((d) => _buildDetectionChip(d)),
            const SizedBox(height: 24),
          ],

          // Action button
          if (!isLowConfidence && !requiresTech)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onAnalysisComplete(_result!),
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
        color: color.withOpacity(0.1),
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

  Widget _buildWarningCard() {
    return Card(
      color: AppColors.warning.withOpacity(0.1),
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
                    _result!.isLowConfidence
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
