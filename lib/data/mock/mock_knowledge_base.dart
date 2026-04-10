import '../models/analysis_result.dart';
import '../models/detection.dart';
import '../models/repair_step.dart';

/// Local repair knowledge base for belt-driven water pumps.
/// This provides deterministic mock data for demo reliability.
class MockKnowledgeBase {
  /// Get mock analysis result based on predefined scenarios.
  /// In production, this would be replaced by real Gemma inference.
  static AnalysisResult getMockResult(String scenario) {
    switch (scenario) {
      case 'loose_belt':
        return _looseBeltResult;
      case 'worn_belt':
        return _wornBeltResult;
      case 'misaligned_belt':
        return _misalignedBeltResult;
      default:
        return AnalysisResult.lowConfidence('Unknown scenario: $scenario');
    }
  }

  /// Sample images for demo mode with their expected fault types.
  static const Map<String, String> sampleImages = {
    'loose_belt': 'assets/images/sample_pumps/loose_belt.jpg',
    'worn_belt': 'assets/images/sample_pumps/worn_belt.jpg',
    'misaligned_belt': 'assets/images/sample_pumps/misaligned_belt.jpg',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // MOCK RESULTS - These simulate what Gemma would return
  // ─────────────────────────────────────────────────────────────────────────

  static final AnalysisResult _looseBeltResult = AnalysisResult(
    machineType: 'belt_driven_water_pump',
    issueType: 'loose_belt',
    confidence: 0.87,
    summary: 'Detected excessive belt sag indicating loose belt tension. This reduces power transmission efficiency and can cause slippage.',
    detections: [
      Detection(
        label: 'belt',
        x: 0.25,
        y: 0.35,
        width: 0.50,
        height: 0.15,
        severity: 'medium',
      ),
      Detection(
        label: 'sag_zone',
        x: 0.40,
        y: 0.45,
        width: 0.20,
        height: 0.10,
        severity: 'high',
      ),
    ],
    repairSteps: [
      RepairStep(
        stepNumber: 1,
        title: 'Turn Off Power',
        instruction: 'Ensure the pump motor is completely powered off and cannot accidentally start.',
        warning: 'CRITICAL: Never work on a running pump. Lock out power source if possible.',
      ),
      RepairStep(
        stepNumber: 2,
        title: 'Check Belt Tension',
        instruction: 'Press down on the belt midway between pulleys. It should deflect about 1/2 inch (12mm) with moderate pressure.',
        warning: null,
      ),
      RepairStep(
        stepNumber: 3,
        title: 'Loosen Motor Mount Bolts',
        instruction: 'Use a wrench to loosen the bolts that hold the motor to its mounting bracket.',
        warning: 'Do not remove bolts completely - just loosen enough to slide motor.',
      ),
      RepairStep(
        stepNumber: 4,
        title: 'Adjust Motor Position',
        instruction: 'Move the motor away from the pump to increase belt tension. Use a pry bar if needed.',
        warning: null,
      ),
      RepairStep(
        stepNumber: 5,
        title: 'Test and Tighten',
        instruction: 'Check tension again. If correct, tighten motor mount bolts while holding position.',
        warning: 'Re-check tension after tightening - it may change slightly.',
      ),
    ],
    stopConditions: [
      'If belt is cracked or frayed, replace instead of adjusting',
      'If motor mounts are damaged, seek technician help',
    ],
  );

  static final AnalysisResult _wornBeltResult = AnalysisResult(
    machineType: 'belt_driven_water_pump',
    issueType: 'worn_belt',
    confidence: 0.92,
    summary: 'Visible cracks and wear patterns detected on belt surface. Belt replacement recommended.',
    detections: [
      Detection(
        label: 'belt',
        x: 0.25,
        y: 0.35,
        width: 0.50,
        height: 0.15,
        severity: 'high',
      ),
      Detection(
        label: 'worn_area',
        x: 0.35,
        y: 0.38,
        width: 0.15,
        height: 0.08,
        severity: 'high',
      ),
      Detection(
        label: 'crack_zone',
        x: 0.55,
        y: 0.40,
        width: 0.10,
        height: 0.06,
        severity: 'medium',
      ),
    ],
    repairSteps: [
      RepairStep(
        stepNumber: 1,
        title: 'Turn Off Power',
        instruction: 'Disconnect power to the pump motor. Verify it cannot start.',
        warning: 'CRITICAL: Electrical safety first. Use lockout tagout if available.',
      ),
      RepairStep(
        stepNumber: 2,
        title: 'Loosen Motor Mount',
        instruction: 'Loosen the motor mounting bolts to release belt tension.',
        warning: null,
      ),
      RepairStep(
        stepNumber: 3,
        title: 'Remove Old Belt',
        instruction: 'Slip the old belt off both pulleys. Note the belt routing for reinstallation.',
        warning: 'Take a photo of belt routing before removal if unsure.',
      ),
      RepairStep(
        stepNumber: 4,
        title: 'Clean Pulleys',
        instruction: 'Wipe down both pulleys to remove dust, oil, or debris.',
        warning: null,
      ),
      RepairStep(
        stepNumber: 5,
        title: 'Install New Belt',
        instruction: 'Place the new belt on pulleys following the same routing. Do not force or pry excessively.',
        warning: 'Ensure belt seats properly in pulley grooves.',
      ),
      RepairStep(
        stepNumber: 6,
        title: 'Adjust Tension',
        instruction: 'Move motor to achieve proper tension (1/2 inch deflection). Tighten mounts.',
        warning: null,
      ),
    ],
    stopConditions: [
      'If pulleys are damaged, seek technician help',
      'If unsure of belt size, consult equipment manual',
    ],
  );

  static final AnalysisResult _misalignedBeltResult = AnalysisResult(
    machineType: 'belt_driven_water_pump',
    issueType: 'misaligned_belt',
    confidence: 0.84,
    summary: 'Belt appears to be running off-center on one or more pulleys. This causes uneven wear and premature failure.',
    detections: [
      Detection(
        label: 'belt',
        x: 0.25,
        y: 0.35,
        width: 0.50,
        height: 0.15,
        severity: 'medium',
      ),
      Detection(
        label: 'misalignment_zone',
        x: 0.60,
        y: 0.32,
        width: 0.15,
        height: 0.20,
        severity: 'high',
      ),
    ],
    repairSteps: [
      RepairStep(
        stepNumber: 1,
        title: 'Turn Off Power',
        instruction: 'Ensure pump is powered off and cannot start.',
        warning: 'Safety first - verify power is disconnected.',
      ),
      RepairStep(
        stepNumber: 2,
        title: 'Inspect Pulley Alignment',
        instruction: 'Use a straightedge or string to check if both pulleys are in the same plane.',
        warning: null,
      ),
      RepairStep(
        stepNumber: 3,
        title: 'Check Motor Mount',
        instruction: 'Inspect motor mounting bracket for damage or wear that could cause misalignment.',
        warning: null,
      ),
      RepairStep(
        stepNumber: 4,
        title: 'Adjust Motor Position',
        instruction: 'Loosen mounts and adjust motor position until pulleys align properly.',
        warning: 'This may require shimming the motor base.',
      ),
      RepairStep(
        stepNumber: 5,
        title: 'Verify and Test',
        instruction: 'Tighten all bolts. Manually rotate belt to verify smooth operation before powering on.',
        warning: 'Run pump briefly and observe belt tracking.',
      ),
    ],
    stopConditions: [
      'If motor mount is bent or damaged, seek technician help',
      'If pulleys cannot be aligned with adjustment, replacement may be needed',
    ],
  );
}
