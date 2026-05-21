enum WetFaceValidationResult { approved, rejected, unavailable }

class WetFaceValidationService {
  const WetFaceValidationService();

  Future<WetFaceValidationResult> validateMock() async {
    // Delay intencional para simular una llamada real a camara/backend y poder
    // probar estados de carga en la UI.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Sprint 1 solo valida el flujo visual. La decision real queda para
    // Cloudflare/Gemini en Sprint 2.
    return WetFaceValidationResult.approved;
  }
}
