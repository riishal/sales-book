import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_selection_page.dart';
import 'invoice_page.dart';
import 'add_product_page.dart';
import '../widgets/selected_product_card.dart';

class AddVendorPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;
  final bool isEdit;

  const AddVendorPage({
    super.key,
    this.docId,
    this.existingData,
    this.isEdit = false,
  });

  @override
  State<AddVendorPage> createState() => _AddVendorPageState();
}

class _AddVendorPageState extends State<AddVendorPage> {
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
        builder: (context) => ProductSelectionPage(
          selectedProducts: _selectedProducts,
          isPurchase: true,
        ),
      ),
    );
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        _selectedProducts = result;
        _calculateTotal();
      });
    }
  }

  Future<void> _saveVendor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final paidNow = double.tryParse(_paidNowController.text) ?? 0.0;

    // Common data for both add and update
    Map<String, dynamic> vendorData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'previousBalance': double.parse(_previousBalanceController.text),
      'currentBill': _grandTotal,
      'additionalCharge': double.parse(_additionalChargeController.text),
      'discount': double.parse(_discountController.text),
      'tax': double.parse(_taxController.text),
      'products': _selectedProducts,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Data for invoice needs a concrete paidNow value.
    final invoiceData = Map<String, dynamic>.from(vendorData);
    invoiceData['paidNow'] = paidNow;

    try {
      final batch = FirebaseFirestore.instance.batch();
      DocumentReference vendorRef;

      if (widget.docId != null) {
        // Existing vendor
        vendorRef = FirebaseFirestore.instance
            .collection('vendors')
            .doc(widget.docId);
        if (widget.isEdit) {
          vendorData['paidNow'] = paidNow;
          batch.update(vendorRef, vendorData);
        } else {
          batch.update(vendorRef, {
            'currentBill': FieldValue.increment(_transactionTotal),
            'paidNow': FieldValue.increment(paidNow),
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // New vendor
        vendorRef = FirebaseFirestore.instance.collection('vendors').doc();
        vendorData['paidNow'] = paidNow;
        batch.set(vendorRef, vendorData);
      }

      if (!widget.isEdit) {
        // Create a transaction record
        final transactionRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc();
        batch.set(transactionRef, {
          'entityId': vendorRef.id,
          'entityName': _nameController.text,
          'entityType': 'Vendor',
          'type': 'Purchase',
          'amount': _transactionTotal,
          'paidNow': paidNow,
          'products': _selectedProducts,
          'additionalCharge': double.parse(_additionalChargeController.text),
          'discount': double.parse(_discountController.text),
          'tax': double.parse(_taxController.text),
          'previousBalance': double.parse(_previousBalanceController.text),
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Get all product names to fetch them in a single query
        final productNames = _selectedProducts.map((p) => p['name']).toList();
        if (productNames.isNotEmpty) {
          final productQuery = await FirebaseFirestore.instance
              .collection('products')
              .where('name', whereIn: productNames)
              .get();

          // Create a map for quick lookups
          final productDocs = {
            for (var doc in productQuery.docs)
              doc.data()['name']: doc.reference,
          };

          for (var product in _selectedProducts) {
            if (productDocs.containsKey(product['name'])) {
              final productDocRef = productDocs[product['name']]!;
              batch.update(productDocRef, {
                'qty': FieldValue.increment((product['qty'] as num).toInt()),
                'price': product['rate'],
              });
            }
          }
        }
      }

      await batch.commit();

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePage(
            docId: vendorRef.id,
            data: invoiceData,
            type: 'vendor',
          ),
        ),
      );
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
          widget.isEdit
              ? 'Edit Vendor'
              : (widget.docId != null ? 'New Purchase' : 'Add Vendor'),
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
                    prefixIcon: Icon(Icons.store),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectProducts,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(
                          'Select Products (${_selectedProducts.length})',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddProductPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New Product'),
                      ),
                    ),
                  ],
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
                        'Bill Amount: ﷼${_transactionTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Balance: ${_previousBalanceController.text}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: ﷼${_grandTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
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
                  onPressed: _saveVendor,
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
          isPurchase: true, // It's a purchase
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
