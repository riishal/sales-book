import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_selection_page.dart';
import 'invoice_page.dart';
import '../widgets/selected_product_card.dart';

class AddCustomerPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;
  final bool isEdit;

  const AddCustomerPage({
    super.key,
    this.docId,
    this.existingData,
    this.isEdit = false,
  });

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _previousBalanceController = TextEditingController(text: '0');
  final _additionalChargeController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _paidNowController = TextEditingController(text: '0');
  List<Map<String, dynamic>> _selectedProducts = [];
  double _transactionTotal = 0;
  double _grandTotal = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      _phoneController.text = widget.existingData!['phone'] ?? '';
      if (widget.isEdit) {
        _previousBalanceController.text =
            (widget.existingData!['previousBalance'] ?? 0).toString();
      } else {
        double previousBalance =
            (widget.existingData!['currentBill'] ?? 0.0) -
            (widget.existingData!['paidNow'] ?? 0.0);
        _previousBalanceController.text = previousBalance.toStringAsFixed(2);
      }
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    double subtotal = 0;
    for (var product in _selectedProducts) {
      subtotal += (product['rate'] as double) * (product['qty'] as num);
    }
    double additional = double.tryParse(_additionalChargeController.text) ?? 0;
    double discount = double.tryParse(_discountController.text) ?? 0;
    double tax = double.tryParse(_taxController.text) ?? 0;
    double previous = double.tryParse(_previousBalanceController.text) ?? 0;

    _transactionTotal =
        subtotal + additional - discount + (subtotal * tax / 100);
    _grandTotal = _transactionTotal + previous;
    setState(() {});
  }

  Future<void> _selectProducts() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductSelectionPage(selectedProducts: _selectedProducts),
      ),
    );
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        _selectedProducts = result;
        _calculateTotal();
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final paidNow = double.tryParse(_paidNowController.text) ?? 0.0;

    // Common data for both add and update
    Map<String, dynamic> customerData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'previousBalance':
          double.tryParse(_previousBalanceController.text) ?? 0.0,
      'currentBill': _grandTotal,
      'additionalCharge':
          double.tryParse(_additionalChargeController.text) ?? 0.0,
      'discount': double.tryParse(_discountController.text) ?? 0.0,
      'tax': double.tryParse(_taxController.text) ?? 0.0,
      'products': _selectedProducts,
    };

    // Data for invoice needs a concrete paidNow value.
    final invoiceData = Map<String, dynamic>.from(customerData);
    invoiceData['paidNow'] = paidNow;

    try {
      final batch = FirebaseFirestore.instance.batch();
      DocumentReference customerRef;

      if (widget.docId != null) {
        // Existing customer
        customerRef = FirebaseFirestore.instance
            .collection('customers')
            .doc(widget.docId);
        if (widget.isEdit) {
          customerData['paidNow'] = paidNow;
          batch.update(customerRef, customerData);
        } else {
          batch.update(customerRef, {
            'currentBill': FieldValue.increment(_transactionTotal),
            'paidNow': FieldValue.increment(paidNow),
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // New customer
        customerRef = FirebaseFirestore.instance.collection('customers').doc();
        customerData['paidNow'] = paidNow;
        customerData['timestamp'] = FieldValue.serverTimestamp();
        batch.set(customerRef, customerData);
      }

      if (!widget.isEdit) {
        // Create a transaction record
        final transactionRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc();
        batch.set(transactionRef, {
          'entityId': customerRef.id,
          'entityName': _nameController.text,
          'entityType': 'Customer',
          'type': 'Sale',
          'amount': _transactionTotal,
          'paidNow': paidNow,
          'products': _selectedProducts,
          'additionalCharge':
              double.tryParse(_additionalChargeController.text) ?? 0.0,
          'discount': double.tryParse(_discountController.text) ?? 0.0,
          'tax': double.tryParse(_taxController.text) ?? 0.0,
          'previousBalance':
              double.tryParse(_previousBalanceController.text) ?? 0.0,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Chunk product IDs into lists of 30
        final productIds = _selectedProducts.map((p) => p['id']).toList();
        for (var i = 0; i < productIds.length; i += 30) {
          final chunk = productIds.sublist(
            i,
            i + 30 > productIds.length ? productIds.length : i + 30,
          );
          final productQuery = await FirebaseFirestore.instance
              .collection('products')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          for (var doc in productQuery.docs) {
            final product = _selectedProducts.firstWhere(
              (p) => p['id'] == doc.id,
            );
            batch.update(doc.reference, {
              'qty': FieldValue.increment(-(product['qty'] as num).toInt()),
              'retailPrice': product['rate'],
            });
          }
        }
      }

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePage(
            docId: customerRef.id,
            data: invoiceData,
            type: 'customer',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? 'Edit Customer'
              : (widget.docId != null ? 'New Sale' : 'Add Customer'),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  enabled: widget.docId == null || widget.isEdit,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  enabled: widget.docId == null || widget.isEdit,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _previousBalanceController,
                  decoration: const InputDecoration(
                    labelText: 'Previous Balance',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotal(),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _selectProducts,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('Select Products (${_selectedProducts.length})'),
                ),
                const SizedBox(height: 16),
                _buildSelectedProductsList(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _additionalChargeController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Charge',
                    prefixIcon: Icon(Icons.add_circle_outline),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotal(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(
                    labelText: 'Discount',
                    prefixIcon: Icon(Icons.remove_circle_outline),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotal(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxController,
                  decoration: const InputDecoration(
                    labelText: 'Tax (%)',
                    prefixIcon: Icon(Icons.receipt),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotal(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Products: ${_selectedProducts.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Bill Amount: ﷼${_transactionTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Balance: ${_previousBalanceController.text}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: ﷼${_grandTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paidNowController,
                  decoration: const InputDecoration(
                    labelText: 'Paid Now',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveCustomer,
                  child: const Text('Save', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSelectedProductsList() {
    if (_selectedProducts.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedProducts.length,
      itemBuilder: (context, index) {
        final product = _selectedProducts[index];
        return SelectedProductCard(
          product: product,
          isPurchase: false, // It's a sale, so not a purchase
          onUpdate: (updatedProduct) {
            setState(() {
              _selectedProducts[index] = {...product, ...updatedProduct};
              _calculateTotal();
            });
          },
          onRemove: () {
            setState(() {
              _selectedProducts.removeAt(index);
              _calculateTotal();
            });
          },
        );
      },
    );
  }
}
