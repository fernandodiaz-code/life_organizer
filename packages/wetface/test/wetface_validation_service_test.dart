import 'package:flutter_test/flutter_test.dart';
import 'package:wetface/wetface.dart';

void main() {
  test('mock validation approves the Sprint 1 flow', () async {
    const service = WetFaceValidationService();

    await expectLater(
      service.validateMock(),
      completion(WetFaceValidationResult.approved),
    );
  });
}

