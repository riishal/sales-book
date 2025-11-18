import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const AddProductPage({super.key, this.docId, this.existingData});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _qtyController = TextEditingController(text: '0');
  final _unitController = TextEditingController(text: 'pcs');
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      _priceController.text = (widget.existingData!['price'] ?? 0).toString();
      _retailPriceController.text = (widget.existingData!['retailPrice'] ?? 0).toString();
      _qtyController.text = (widget.existingData!['qty'] ?? 0).toString();
      _unitController.text = widget.existingData!['unit'] ?? 'pcs';
      _discountController.text = (widget.existingData!['discount'] ?? 0).toString();
      _taxController.text = (widget.existingData!['tax'] ?? 0).toString();
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'retailPrice': double.parse(_retailPriceController.text),
      'qty': double.parse(_qtyController.text),
      'unit': _unitController.text,
      'discount': double.parse(_discountController.text),
      'tax': double.parse(_taxController.text),
      'total': double.parse(_priceController.text) * double.parse(_qtyController.text),
      'timestamp': FieldValue.serverTimestamp(),
    };
    try {
      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.docId)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('products').add(data);
      }
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
          widget.docId != null ? 'Edit Product' : 'Add Product',
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
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration('Product Name', Icons.inventory_2),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: _buildInputDecoration('Purchase Price', Icons.attach_money),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _retailPriceController,
                    decoration: _buildInputDecoration('Retail Price', Icons.money),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _qtyController,
                          decoration: _buildInputDecoration('Quantity', null),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration: _buildInputDecoration('Unit', null),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _discountController,
                    decoration: _buildInputDecoration('Discount (%)', Icons.discount),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxController,
                    decoration: _buildInputDecoration('Tax (%)', Icons.receipt),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Product',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
