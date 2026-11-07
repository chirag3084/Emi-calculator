import 'package:flutter_test/flutter_test.dart';
import 'package:emi_calculator/emi_result.dart';

void main() {
  test('parses API response fields into an EMI result', () {
    final result = EmiResult.fromJson({
      'principal': 1000000.0,
      'annual_interest_rate': 8.5,
      'tenure_months': 240,
      'monthly_emi': 8678.23,
      'total_interest': 1082775.46,
      'total_payment': 2082775.46,
    });

    expect(result.principal, 1000000.0);
    expect(result.annualInterestRate, 8.5);
    expect(result.tenureMonths, 240);
    expect(result.monthlyEmi, 8678.23);
  });
}
