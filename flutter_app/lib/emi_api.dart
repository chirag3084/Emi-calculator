import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'emi_result.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class EmiApiException implements Exception {
  const EmiApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EmiApi {
  EmiApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? apiBaseUrl).replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<EmiResult> calculate({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/calculate-emi/'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'principal': principal,
              'annual_interest_rate': annualInterestRate,
              'tenure_months': tenureMonths,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final Map<String, dynamic> payload = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return EmiResult.fromJson(payload);
      }
      throw EmiApiException(
        payload['error']?.toString() ?? 'The calculation could not be completed.',
      );
    } on TimeoutException {
      throw const EmiApiException('The server took too long to respond. Try again.');
    } on http.ClientException {
      throw const EmiApiException(
        'Could not reach the Django server. Check the API URL and that the server is running.',
      );
    } on FormatException {
      throw const EmiApiException('The server returned an unreadable response.');
    }
  }
}
