import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/analysis_result.dart';

/// Step-by-step repair guidance screen.
class RepairScreen extends StatefulWidget {
  final AnalysisResult result;
  final VoidCallback onComplete;

  const RepairScreen({
    super.key,
    required this.result,
    required this.onComplete,
  });

  @override
  State<RepairScreen> createState() => _RepairScreenState();
}

class _RepairScreenState extends State<RepairScreen> {
  int _currentStepIndex = 0;
  final List<bool> _completedSteps = [];

  @override
  void initState() {
    super.initState();
    _completedSteps.addAll(List.generate(widget.result.repairSteps.length, (_) => false));
  }

  void _nextStep() {
    if (_currentStepIndex < widget.result.repairSteps.length - 1) {
      setState(() {
        _completedSteps[_currentStepIndex] = true;
        _currentStepIndex++;
      });
    } else {
      _completeRepair();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }


  void _completeRepair() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repair Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            const Text(
              'Great job! Follow these final steps:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Double-check all bolts are tight\n'
              '2. Clear tools and debris from area\n'
              '3. Restore power and test run\n'
              '4. Monitor for unusual noise or vibration',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onComplete();
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.result.repairSteps[_currentStepIndex];
    final isLastStep = _currentStepIndex == widget.result.repairSteps.length - 1;
    final progress = (_currentStepIndex + 1) / widget.result.repairSteps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Guide'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showBackConfirmation(),
        ),
        actions: [
          TextButton(
            onPressed: _completeRepair,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(value: progress),

          // Step indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentStepIndex + 1} of ${widget.result.repairSteps.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}% complete',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step title
                  Text(
                    currentStep.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Step instruction
                  Text(
                    currentStep.instruction,
                    style: const TextStyle(fontSize: 18, height: 1.6),
                  ),
                  const SizedBox(height: 24),

                  // Warning if present
                  if (currentStep.warning != null) ...[
                    _buildWarningCard(currentStep.warning!),
                    const SizedBox(height: 24),
                  ],

                  // Safety tips
                  _buildSafetyTips(),
                ],
              ),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(isLastStep),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String warning) {
    return Card(
      color: AppColors.warning.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warning',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTips() {
    return Card(
      color: AppColors.info.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: AppColors.info),
                const SizedBox(width: 8),
                const Text(
                  'Safety Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Always verify power is off before working\n'
              '• Use proper tools for the job\n'
              '• Wear safety glasses when working with belts\n'
              '• Keep hands clear of moving parts\n'
              '• If unsure, consult a technician',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isLastStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStepIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_currentStepIndex > 0) const SizedBox(width: 16),

          // Next/Complete button
          Expanded(
            flex: _currentStepIndex > 0 ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: _nextStep,
              icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward),
              label: Text(isLastStep ? 'Complete Repair' : 'Next Step'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Repair Guide?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onComplete();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
