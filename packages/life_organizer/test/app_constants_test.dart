import 'package:flutter_test/flutter_test.dart';
import 'package:life_organizer/core/constants.dart';

void main() {
  test('weekday constants keep UI and database values aligned', () {
    expect(AppConstants.diasSemana, hasLength(7));
    expect(AppConstants.diasDb, hasLength(AppConstants.diasSemana.length));
    expect(AppConstants.diasDb, contains('miercoles'));
  });
}

