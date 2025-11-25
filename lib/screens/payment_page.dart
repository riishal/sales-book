import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  final String docId;
  final String type; // 'customers' or 'vendors'
  final double currentBalance;

  const PaymentPage({
    super.key,
    required this.docId,
    required this.type,
    required this.currentBalance,
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final docRef = FirebaseFirestore.instance.collection(widget.type).doc(widget.docId);

      // Determine the transaction details based on the type
      String transactionDetail;
      Object newPaidNowValue;

      final currentDoc = await docRef.get();

      if (widget.type == 'customers') {
        if (_transactionType == TransactionType.getCash) {
          transactionDetail = 'Cash Received from Customer';
          newPaidNowValue = FieldValue.increment(amount);
        } else { // Pay Cash
          transactionDetail = 'Cash Paid to Customer';
          newPaidNowValue = FieldValue.increment(-amount);
        }
      } else { // vendors
        if (_transactionType == TransactionType.payCash) {
          transactionDetail = 'Cash Paid to Vendor';
          newPaidNowValue = FieldValue.increment(amount);
        } else { // Get Cash
          transactionDetail = 'Cash Received from Vendor';
          newPaidNowValue = FieldValue.increment(-amount);
        }
      }

      // Create a transaction record
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transactionRef, {
        'entityId': widget.docId,
        'entityType': widget.type == 'customers' ? 'Customer' : 'Vendor',
        'entityName': currentDoc.data()?['name'] ?? 'N/A',
        'type': transactionDetail,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'details': {},
      });

      // Update the customer's or vendor's paidNow field
      batch.update(docRef, {'paidNow': newPaidNowValue});

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the balance text based on type and balance value
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
    } else { // vendors
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
      appBar: AppBar(
        title: const Text('Cash Transaction'),
      ),
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
                  const Text('Select Transaction Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  RadioListTile<TransactionType>(
                    title: const Text('Get Cash'),
                    value: TransactionType.getCash,
                    groupValue: _transactionType,
                    onChanged: (TransactionType? value) {
                      setState(() {
                        _transactionType = value!;
                      });
                    },
                  ),
                  RadioListTile<TransactionType>(
                    title: const Text('Pay Cash'),
                    value: TransactionType.payCash,
                    groupValue: _transactionType,
                    onChanged: (TransactionType? value) {
                      setState(() {
                        _transactionType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTransaction,
                    child: const Text('Save Transaction', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
