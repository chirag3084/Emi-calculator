class EmiResult {
  const EmiResult({
    required this.principal,
    required this.annualInterestRate,
    required this.tenureMonths,
    required this.monthlyEmi,
    required this.totalInterest,
    required this.totalPayment,
  });

  final double principal;
  final double annualInterestRate;
  final int tenureMonths;
  final double monthlyEmi;
  final double totalInterest;
  final double totalPayment;

  factory EmiResult.fromJson(Map<String, dynamic> json) {
    return EmiResult(
      principal: (json['principal'] as num).toDouble(),
      annualInterestRate: (json['annual_interest_rate'] as num).toDouble(),
      tenureMonths: (json['tenure_months'] as num).toInt(),
      monthlyEmi: (json['monthly_emi'] as num).toDouble(),
      totalInterest: (json['total_interest'] as num).toDouble(),
      totalPayment: (json['total_payment'] as num).toDouble(),
    );
  }
}
