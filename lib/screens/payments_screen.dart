import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/payment_service.dart';
import '../state/app_session.dart';
import '../widgets/jobflow_app_bar.dart';
import '../widgets/section_card.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _paymentService = PaymentService();
  final _productController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final assignment = AppSession.activeAssignment;
    if (assignment != null) {
      _productController.text = assignment.jobTitle;
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _takePayment() async {
    if (_isSubmitting) {
      return;
    }

    final productName = _productController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (productName.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a product name and valid amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final assignment = AppSession.activeAssignment;
    final result = await _paymentService.createCheckoutSession(
      productName: productName,
      amount: amount,
      organizationClientId: assignment?.organizationClientId,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!mounted) {
      return;
    }

    if (result == null || result.url == null || result.url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start payment checkout.')),
      );
      return;
    }

    final uri = Uri.tryParse(result.url!);
    final launched = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) {
      return;
    }

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open payment link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JobFlowAppBar(title: 'Payments'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Take a payment', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _productController,
                  decoration: const InputDecoration(labelText: 'Product or job'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _takePayment,
                    icon: const Icon(Icons.credit_card),
                    label: Text(_isSubmitting ? 'Starting checkout...' : 'Take payment'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const Text('• Invoice #1042 paid in the office'),
                const SizedBox(height: 8),
                const Text('• Invoice #1045 awaiting card swipe'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
