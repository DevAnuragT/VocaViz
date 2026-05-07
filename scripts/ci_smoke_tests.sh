#!/usr/bin/env bash
set -euo pipefail

flutter test \
  test/models/analysis_result_test.dart \
  test/models/detection_test.dart \
  test/models/repair_step_test.dart \
  test/models/history_entry_test.dart \
  test/services/inference_service_test.dart \
  test/services/history_service_test.dart \
  test/analysis_controller_test.dart \
  test/app_state_provider_test.dart \
  test/preferences_test.dart \
  --concurrency=1
