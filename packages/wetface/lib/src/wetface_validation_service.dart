enum WetFaceValidationResult {
  approved,
  rejected,
  unavailable,
}

class WetFaceValidationService {
  const WetFaceValidationService();

  Future<WetFaceValidationResult> validateMock() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return WetFaceValidationResult.approved;
  }
}

