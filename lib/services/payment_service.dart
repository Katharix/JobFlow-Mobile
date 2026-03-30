import 'dart:convert';

import '../constants/app_constants.dart';
import '../state/app_session.dart';
import 'api_client.dart';

class PaymentCheckoutResult {
  PaymentCheckoutResult({
    required this.clientSecret,
    required this.url,
    required this.providerPaymentId,
  });

  final String? clientSecret;
  final String? url;
  final String? providerPaymentId;

  factory PaymentCheckoutResult.fromApi(Map<String, dynamic> json) {
    return PaymentCheckoutResult(
      clientSecret: json['clientSecret']?.toString(),
      url: json['url']?.toString(),
      providerPaymentId: json['providerPaymentId']?.toString(),
    );
  }
}

class PaymentService {
  PaymentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConstants.apiBaseUrl);

  final ApiClient _apiClient;

  Future<PaymentCheckoutResult?> createCheckoutSession({
    required String productName,
    required double amount,
    String? organizationClientId,
    String? invoiceId,
    String? email,
  }) async {
    if (!AppSession.isAuthenticated) {
      return null;
    }

    final body = <String, dynamic>{
      'mode': 'payment',
      'productName': productName,
      'amount': amount,
      'quantity': 1,
      if (organizationClientId != null && organizationClientId.isNotEmpty)
        'organizationClientId': organizationClientId,
      if (invoiceId != null && invoiceId.isNotEmpty) 'invoiceId': invoiceId,
      if (email != null && email.isNotEmpty) 'email': email,
    };

    final response = await _apiClient.postJson(AppConstants.paymentsCheckoutPath, body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentCheckoutResult.fromApi(data);
  }

  Future<PaymentCheckoutResult?> createDeposit({
    required String invoiceId,
    required double amount,
    String? organizationClientId,
    String productName = 'Deposit',
  }) async {
    if (!AppSession.isAuthenticated) {
      return null;
    }

    final body = <String, dynamic>{
      'invoiceId': invoiceId,
      'amount': amount,
      'productName': productName,
      if (organizationClientId != null && organizationClientId.isNotEmpty)
        'organizationClientId': organizationClientId,
    };

    final response = await _apiClient.postJson(AppConstants.paymentsDepositPath, body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentCheckoutResult.fromApi(data);
  }
}
