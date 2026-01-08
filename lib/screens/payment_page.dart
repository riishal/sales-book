import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salesbook/screens/payment_invoice.dart';

class PaymentPage extends StatefulWidget {
  final String docId;
  final String type; // 'customers' or 'vendors'
  final double currentBalance;
  final String entityName;

  const PaymentPage({
    super.key,
    required this.docId,
    required this.type,
    required this.currentBalance,
    required this.entityName,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

enum TransactionType { getCash, payCash }

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  TransactionType _transactionType = TransactionType.getCash;
  bool _isLoading = false;
  late double newBalance;

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final docRef = FirebaseFirestore.instance
          .collection(widget.type)
          .doc(widget.docId);

      final currentDoc = await docRef.get();
      final entityName = currentDoc.data()?['name'] ?? widget.entityName;

      // Start with current balance passed from parent
      double oldBalance = widget.currentBalance;
      newBalance = oldBalance;

      String transactionDetail;
      FieldValue paidNowIncrement;

      if (widget.type == 'customers') {
        if (_transactionType == TransactionType.getCash) {
          // Customer pays you → reduce "You will get"
          transactionDetail = 'Cash Received from Customer';
          paidNowIncrement = FieldValue.increment(amount);
          newBalance = oldBalance - amount;
        } else {
          // You pay customer (refund) → increase "You will get"
          transactionDetail = 'Cash Paid to Customer';
          paidNowIncrement = FieldValue.increment(-amount);
          newBalance = oldBalance + amount;
        }
      } else {
        // vendors
        if (_transactionType == TransactionType.payCash) {
          // You pay vendor → reduce "You will pay"
          transactionDetail = 'Cash Paid to Vendor';
          paidNowIncrement = FieldValue.increment(amount);
          newBalance = oldBalance - amount;
        } else {
          // Vendor pays you back → increase "You will pay" (or reduce your credit)
          transactionDetail = 'Cash Received from Vendor';
          paidNowIncrement = FieldValue.increment(-amount);
          newBalance = oldBalance + amount;
        }
      }

      final transactionRef = FirebaseFirestore.instance
          .collection('transactions')
          .doc();

      final transactionData = {
        'entityId': widget.docId,
        'entityType': widget.type == 'customers' ? 'Customer' : 'Vendor',
        'entityName': entityName,
        'type': transactionDetail,
        'amount': amount,
        'timestamp': Timestamp.now(),
        'newBalance': newBalance,
        'details': {},
      };

      batch.set(transactionRef, transactionData);
      batch.update(docRef, {'paidNow': paidNowIncrement});

      await batch.commit();

      if (mounted) {
        setState(() => _isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentInvoicePage(
              transaction: transactionData,
              balance: newBalance,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.currentBalance;
    String balanceText;
    Color balanceColor;

    if (widget.type == 'customers') {
      if (balance > 0) {
        balanceText = 'You will get: ﷼${balance.toStringAsFixed(2)}';
        balanceColor = Colors.green;
      } else if (balance < 0) {
        balanceText = 'You will pay: ﷼${(-balance).toStringAsFixed(2)}';
        balanceColor = Colors.red;
      } else {
        balanceText = 'Settled';
        balanceColor = Colors.grey;
      }
    } else {
      if (balance > 0) {
        balanceText = 'You will pay: ﷼${balance.toStringAsFixed(2)}';
        balanceColor = Colors.red;
      } else if (balance < 0) {
        balanceText = 'You will get: ﷼${(-balance).toStringAsFixed(2)}';
        balanceColor = Colors.green;
      } else {
        balanceText = 'Settled';
        balanceColor = Colors.grey;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pay/Get Cash')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Current Balance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            balanceText,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: balanceColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Transaction Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<TransactionType>(
                    title: const Text('Get Cash'),
                    value: TransactionType.getCash,
                    groupValue: _transactionType,
                    onChanged: (value) =>
                        setState(() => _transactionType = value!),
                  ),
                  RadioListTile<TransactionType>(
                    title: const Text('Pay Cash'),
                    value: TransactionType.payCash,
                    groupValue: _transactionType,
                    onChanged: (value) =>
                        setState(() => _transactionType = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter amount';
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Enter valid positive amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTransaction,
                    child: const Text(
                      'Save Transaction',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
