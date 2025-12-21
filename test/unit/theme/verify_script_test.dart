import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Test for scripts/verify_no_adhoc_colors.sh
///
/// Verifies script detects ad-hoc Colors.* usage while excluding
/// risk widget files (RiskPalette is allowed per C4 gate).
///
/// Note: Skipped on web platform (no file system access)
void main() {
  test(
    'verify_no_adhoc_colors.sh executable exists',
    () {
      final script = File('scripts/verify_no_adhoc_colors.sh');
      expect(
        script.existsSync(),
        isTrue,
        reason: 'Verification script must exist',
      );

      // Check executable permission
      final stat = script.statSync();
      final isExecutable = (stat.mode & 0x49) != 0; // Check user execute bit
      expect(
        isExecutable,
        isTrue,
        reason: 'Script must be executable (chmod +x)',
      );
    },
    skip: kIsWeb ? 'File I/O not available on web platform' : null,
  );

  test(
    'verify_no_adhoc_colors.sh detects Colors.* usage',
    () async {
      // This test will FAIL initially when Colors.* exists in app chrome
      // It should PASS after T013-T017 sweep (replacing Colors.* with theme tokens)

      final result = await Process.run('bash', [
        'scripts/verify_no_adhoc_colors.sh',
      ], workingDirectory: Directory.current.path);

      expect(
        result.exitCode,
        equals(0),
        reason:
            'Ad-hoc Colors.* usage found in app chrome. '
            'Expected after T013-T017 sweep. '
            'Excluded files (RiskPalette): risk_palette.dart, risk_banner.dart, risk_result_chip.dart',
      );
    },
    skip: 'Expected to fail before T013-T017 sweep',
  );

  test(
    'verify_no_adhoc_colors.sh excludes risk widget files (C4)',
    () async {
      // Verify exclusion list works - risk widgets CAN use RiskPalette/Colors.*
      final script = File('scripts/verify_no_adhoc_colors.sh');
      final content = await script.readAsString();

      expect(
        content,
        contains('risk_palette.dart'),
        reason: 'Must exclude risk_palette.dart per C4 gate',
      );
      expect(
        content,
        contains('risk_banner.dart'),
        reason: 'Must exclude risk_banner.dart per C4 gate',
      );
      expect(
        content,
        contains('risk_result_chip.dart'),
        reason: 'Must exclude risk_result_chip.dart per C4 gate',
      );
    },
    skip: kIsWeb ? 'File I/O not available on web platform' : null,
  );
}
