import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPage extends StatefulWidget {
  final String entityId;
  final String entityType;
  final double balance;

  const PaymentPage({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.balance,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String _paymentMethod = 'Cash';

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final transactionType = widget.entityType == 'Customer'
        ? 'Payment'
        : 'Purchase';

    try {
      final entityDoc = await FirebaseFirestore.instance
          .collection(widget.entityType.toLowerCase() + 's')
          .doc(widget.entityId)
          .get();
      final entityName = entityDoc.data()?['name'] ?? '';

      // Add transaction record
      await FirebaseFirestore.instance.collection('transactions').add({
        'entityId': widget.entityId,
        'entityName': entityName,
        'entityType': widget.entityType,
        'type': transactionType,
        'amount': amount,
        'paymentMethod': _paymentMethod,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the entity's balance
      final entityRef = FirebaseFirestore.instance
          .collection(widget.entityType.toLowerCase() + 's')
          .doc(widget.entityId);
      await entityRef.update({'paidNow': FieldValue.increment(amount)});

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entityType == 'Vendor' ? 'Pay Cash' : 'Get Cash',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Outstanding Balance: riyal ${widget.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _amountController,
                    decoration: _buildInputDecoration(
                      'Amount',
                      Icons.attach_money,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  _buildPaymentMethodSelector(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _savePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            activeColor: Colors.white,
            title: const Text('Cash', style: TextStyle(color: Colors.white)),
            value: 'Cash',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
          ),
          RadioListTile<String>(
            activeColor: Colors.white,
            title: const Text('Bank', style: TextStyle(color: Colors.white)),
            value: 'Bank',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }
}
