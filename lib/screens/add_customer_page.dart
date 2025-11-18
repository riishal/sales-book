import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_selection_page.dart';
import 'invoice_page.dart';

class AddCustomerPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;
  final bool isEdit;

  const AddCustomerPage({super.key, this.docId, this.existingData, this.isEdit = false});

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
  double _currentBill = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      _phoneController.text = widget.existingData!['phone'] ?? '';
      if (widget.isEdit) {
        _previousBalanceController.text = (widget.existingData!['previousBalance'] ?? 0).toString();
      } else {
        double previousBalance = (widget.existingData!['currentBill'] ?? 0.0) - (widget.existingData!['paidNow'] ?? 0.0);
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
    _currentBill =
        subtotal + additional - discount + (subtotal * tax / 100) + previous;
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

    final paidNow = double.parse(_paidNowController.text);
    final updateData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'previousBalance': double.parse(_previousBalanceController.text),
      'currentBill': _currentBill,
      'additionalCharge': double.parse(_additionalChargeController.text),
      'discount': double.parse(_discountController.text),
      'tax': double.parse(_taxController.text),
      'paidNow': widget.isEdit ? paidNow : FieldValue.increment(paidNow),
      'products': _selectedProducts,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final invoiceData = Map<String, dynamic>.from(updateData);
    if (!widget.isEdit) {
      invoiceData['paidNow'] = (widget.existingData?['paidNow'] ?? 0.0) + paidNow;
    }

    try {
      String? docId = widget.docId;
      if (docId != null) {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(docId)
            .update(updateData);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('customers')
            .add(updateData);
        docId = docRef.id;
      }

      if (!widget.isEdit) {
        // Create a transaction record
        await FirebaseFirestore.instance.collection('transactions').add({
          'entityId': docId,
          'entityName': _nameController.text,
          'entityType': 'Customer',
          'type': 'Sale',
          'amount': _currentBill,
          'paidNow': paidNow,
          'products': _selectedProducts,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update product quantities
        for (var product in _selectedProducts) {
          final productQuery = await FirebaseFirestore.instance
              .collection('products')
              .where('name', isEqualTo: product['name'])
              .get();
          if (productQuery.docs.isNotEmpty) {
            final productDoc = productQuery.docs.first;
            await productDoc.reference.update({
              'qty': FieldValue.increment(-(product['qty'] as num).toDouble()),
            });
          }
        }
      }

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePage(docId: docId!, data: invoiceData, type: 'customer'),
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
          widget.isEdit ? 'Edit Customer' : (widget.docId != null ? 'New Sale' : 'Add Customer'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration('Name', Icons.person),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.white),
                    enabled: widget.docId == null || widget.isEdit,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _buildInputDecoration('Phone', Icons.phone),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.white),
                    enabled: widget.docId == null || widget.isEdit,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _previousBalanceController,
                    decoration: _buildInputDecoration('Previous Balance', Icons.account_balance_wallet),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotal(),
                    style: const TextStyle(color: Colors.white),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _selectProducts,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Select Products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSelectedProductsList(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _additionalChargeController,
                    decoration: _buildInputDecoration('Additional Charge', Icons.add_circle_outline),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotal(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _discountController,
                    decoration: _buildInputDecoration('Discount', Icons.remove_circle_outline),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotal(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxController,
                    decoration: _buildInputDecoration('Tax (%)', Icons.receipt),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotal(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total Bill: ﷼${_currentBill.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _paidNowController,
                    decoration: _buildInputDecoration('Paid Now', Icons.payment),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveCustomer,
                    child: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
          ],
        ),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          child: ListTile(
            title: Text(
              product['name'],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Qty: ${product['qty']}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Text(
              '﷼${(product['rate'] * (product['qty'] as num)).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
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
