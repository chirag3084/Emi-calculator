import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'emi_api.dart';
import 'emi_result.dart';

void main() {
  runApp(const EmiCalculatorApp());
}

const _ink = Color(0xFF172B3A);
const _muted = Color(0xFF718096);
const _teal = Color(0xFF087F78);
const _canvas = Color(0xFFF4F7F8);

class EmiCalculatorApp extends StatelessWidget {
  const EmiCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearEMI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          primary: _teal,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _ink,
            fontSize: 29,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          titleLarge: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(color: _muted, height: 1.45),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          hintStyle: const TextStyle(color: Color(0xFF9AA6B2)),
          prefixStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          suffixStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _teal, width: 1.7),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9485F)),
          ),
        ),
      ),
      home: const EmiHomePage(),
    );
  }
}

class EmiHomePage extends StatefulWidget {
  const EmiHomePage({super.key});

  @override
  State<EmiHomePage> createState() => _EmiHomePageState();
}

class _EmiHomePageState extends State<EmiHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController(text: '5000000');
  final _rateController = TextEditingController(text: '8.5');
  final _yearsController = TextEditingController(text: '20');
  final _api = EmiApi();
  final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  EmiResult? _result;
  String? _error;
  bool _loading = false;

  double get _rate => double.tryParse(_rateController.text) ?? 8.5;
  double get _years => double.tryParse(_yearsController.text) ?? 20;

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.calculate(
        principal: double.parse(_principalController.text.trim()),
        annualInterestRate: double.parse(_rateController.text.trim()),
        tenureMonths: (double.parse(_yearsController.text.trim()) * 12).round(),
      );
      if (!mounted) return;
      setState(() {
        _result = response;
        _loading = false;
      });
    } on EmiApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try the calculation again.';
        _loading = false;
      });
    }
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite) return 'Enter a valid amount';
    if (amount <= 0 || amount > 1000000000) return 'Use an amount up to ₹100 crore';
    return null;
  }

  String? _validateRate(String? value) {
    final rate = double.tryParse(value?.trim() ?? '');
    if (rate == null || !rate.isFinite) return 'Enter a valid rate';
    if (rate < 0 || rate > 100) return 'Enter 0–100%';
    return null;
  }

  String? _validateYears(String? value) {
    final years = double.tryParse(value?.trim() ?? '');
    if (years == null || !years.isFinite) return 'Enter loan years';
    if (years < 1 / 12 || years > 50) return 'Choose up to 50 years';
    return null;
  }

  void _setRate(double value) {
    _rateController.text = value.toStringAsFixed(1);
    setState(() => _error = null);
  }

  void _setYears(double value) {
    _yearsController.text = value.round().toString();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 34),
                  Text('Plan your loan,', style: Theme.of(context).textTheme.headlineMedium),
                  Text('with clarity.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: _teal)),
                  const SizedBox(height: 10),
                  const Text(
                    'See your monthly payment and the full cost of borrowing before you decide.',
                    style: TextStyle(color: _muted, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 26),
                  _buildInputCard(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _loading ? null : _calculate,
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Calculate my EMI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                SizedBox(width: 9),
                                Icon(Icons.arrow_forward_rounded, size: 19),
                              ],
                            ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 13),
                    _ErrorBanner(message: _error!),
                  ],
                  if (_result != null) ...[
                    const SizedBox(height: 27),
                    _buildResult(_result!),
                  ],
                  const SizedBox(height: 25),
                  const Center(
                    child: Text(
                      'Estimate only · Actual lender terms may vary',
                      style: TextStyle(color: Color(0xFF8B98A5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 11),
        const Text('ClearEMI', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F3F1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: _teal, size: 14),
              SizedBox(width: 5),
              Text('Private estimate', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE8EDF0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, color: _teal, size: 19),
                  SizedBox(width: 8),
                  Text('Loan details', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 540;
                  final width = wide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: width,
                        child: _numberField(
                          label: 'Loan amount',
                          controller: _principalController,
                          prefix: '₹',
                          helper: 'Principal borrowed',
                          validator: _validateAmount,
                          decimals: false,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _numberField(
                          label: 'Interest rate',
                          controller: _rateController,
                          suffix: '% p.a.',
                          helper: 'Annual interest',
                          validator: _validateRate,
                          decimals: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _numberField(
                          label: 'Loan tenure',
                          controller: _yearsController,
                          suffix: 'years',
                          helper: 'Repayment period',
                          validator: _validateYears,
                          decimals: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 17),
              _sliderRow(
                label: 'Annual interest',
                value: _rate.clamp(0, 30).toDouble(),
                min: 0,
                max: 30,
                divisions: 60,
                valueLabel: '${_rate.toStringAsFixed(1)}%',
                onChanged: _setRate,
              ),
              const SizedBox(height: 10),
              _sliderRow(
                label: 'Loan tenure',
                value: _years.clamp(1, 30).toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                valueLabel: '${_years.round()} years',
                onChanged: _setYears,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String helper,
    required String? Function(String?) validator,
    String? prefix,
    String? suffix,
    required bool decimals,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(decimals ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')),
          ],
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 15),
          decoration: InputDecoration(prefixText: prefix, suffixText: suffix),
        ),
        const SizedBox(height: 5),
        Text(helper, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(valueLabel, style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: _teal,
            inactiveTrackColor: const Color(0xFFDDE8E7),
            thumbColor: _teal,
            overlayColor: _teal.withOpacity(0.12),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(EmiResult result) {
    final interestShare = result.totalPayment == 0
        ? 0.0
        : (result.totalInterest / result.totalPayment).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_graph_rounded, color: _teal, size: 19),
            SizedBox(width: 8),
            Text('Your estimate', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF087F78), Color(0xFF096760)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MONTHLY EMI', style: TextStyle(color: Color(0xFFC7E6E1), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
              const SizedBox(height: 7),
              Text(
                _currency.format(result.monthlyEmi),
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
              const SizedBox(height: 5),
              Text(
                '${result.annualInterestRate.toStringAsFixed(1)}% annual rate  ·  ${_formatTenure(result.tenureMonths)}',
                style: const TextStyle(color: Color(0xFFD4EBE8), fontSize: 12),
              ),
              const SizedBox(height: 21),
              Container(height: 1, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _darkSummary('Loan amount', _currency.format(result.principal))),
                  const SizedBox(width: 12),
                  Expanded(child: _darkSummary('Total repayment', _currency.format(result.totalPayment))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _lightMetric('Total interest', _currency.format(result.totalInterest), Icons.percent_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _lightMetric('Monthly payments', '${result.tenureMonths}', Icons.calendar_month_rounded)),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE8EDF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Repayment breakdown', style: TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: interestShare,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFBFE2DE),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF0B560)),
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  _legendDot(const Color(0xFFBFE2DE), 'Principal ${_currency.format(result.principal)}'),
                  const Spacer(),
                  _legendDot(const Color(0xFFF0B560), 'Interest ${_currency.format(result.totalInterest)}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTenure(int months) {
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    final yearWord = years == 1 ? 'year' : 'years';
    if (years == 0) return '$months months';
    if (remainingMonths == 0) return '$years $yearWord';
    return '$years $yearWord $remainingMonths mo';
  }

  Widget _darkSummary(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFC7E6E1), fontSize: 11)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _lightMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EDF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _teal, size: 18),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10))),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF2C8CB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB73845), size: 18),
          const SizedBox(width: 9),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF8E303A), fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }
}
