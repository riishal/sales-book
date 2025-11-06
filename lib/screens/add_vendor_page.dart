import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_selection_page.dart';
import 'invoice_page.dart';

class AddVendorPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const AddVendorPage({super.key, this.docId, this.existingData});

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
  List<Map<String, dynamic>> selectedProducts = [];
  double currentBill = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      _phoneController.text = widget.existingData!['phone'] ?? '';
      _previousBalanceController.text =
          (widget.existingData!['previousBalance'] ?? 0).toString();
      _additionalChargeController.text =
          (widget.existingData!['additionalCharge'] ?? 0).toString();
      _discountController.text = (widget.existingData!['discount'] ?? 0)
          .toString();
      _taxController.text = (widget.existingData!['tax'] ?? 0).toString();
      _paidNowController.text = (widget.existingData!['paidNow'] ?? 0)
          .toString();
      selectedProducts = List<Map<String, dynamic>>.from(
        widget.existingData!['products'] ?? [],
      );
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    double subtotal = 0;
    for (var product in selectedProducts) {
      subtotal += (product['rate'] as double) * (product['qty'] as double);
    }
    double additional = double.tryParse(_additionalChargeController.text) ?? 0;
    double discount = double.tryParse(_discountController.text) ?? 0;
    double tax = double.tryParse(_taxController.text) ?? 0;
    double previous = double.tryParse(_previousBalanceController.text) ?? 0;
    currentBill =
        subtotal + additional - discount + (subtotal * tax / 100) + previous;
    setState(() {});
  }

  Future<void> _selectProducts() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductSelectionPage(selectedProducts: selectedProducts),
      ),
    );
    if (result != null) {
      setState(() {
        selectedProducts = result as List<Map<String, dynamic>>;
        _calculateTotal();
      });
    }
  }

  Future<void> _saveVendor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final data = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'previousBalance': double.parse(_previousBalanceController.text),
      'currentBill': currentBill,
      'additionalCharge': double.parse(_additionalChargeController.text),
      'discount': double.parse(_discountController.text),
      'tax': double.parse(_taxController.text),
      'paidNow': double.parse(_paidNowController.text),
      'products': selectedProducts,
      'timestamp': FieldValue.serverTimestamp(),
    };
    try {
      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(widget.docId)
            .update(data);
        Navigator.pop(context);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('vendors')
            .add(data);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                InvoicePage(docId: docRef.id, data: data, type: 'vendor'),
          ),
        );
      }
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
          widget.docId != null ? 'Edit Vendor' : 'Add Vendor',
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
                    decoration: _buildInputDecoration('Name', Icons.store),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _buildInputDecoration('Phone', Icons.phone),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _previousBalanceController,
                    decoration: _buildInputDecoration('Previous Balance', Icons.account_balance_wallet),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotal(),
                    style: const TextStyle(color: Colors.white),
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
                  if (selectedProducts.isNotEmpty)
                    ...selectedProducts.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final product = entry.value;
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
                          subtitle: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  initialValue: product['qty'].toString(),
                                  decoration: _buildInputDecoration('Qty', null),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    selectedProducts[idx]['qty'] =
                                        double.tryParse(v) ?? 1;
                                    _calculateTotal();
                                  },
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Rate: ﷼${product['rate']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                selectedProducts.removeAt(idx);
                              });
                              _calculateTotal();
                            },
                          ),
                        ),
                      );
                    }),
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
                      'Current Bill: ﷼${currentBill.toStringAsFixed(2)}',
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
                    onPressed: _saveVendor,
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
