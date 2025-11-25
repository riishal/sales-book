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
      'qty': int.parse(_qtyController.text),
      'unit': _unitController.text,
      'discount': double.parse(_discountController.text),
      'tax': double.parse(_taxController.text),
      'total': double.parse(_priceController.text) * int.parse(_qtyController.text),
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
                    labelText: 'Product Name',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _retailPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Retail Price',
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _qtyController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(
                    labelText: 'Discount (%)',
                    prefixIcon: Icon(Icons.discount),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxController,
                  decoration: const InputDecoration(
                    labelText: 'Tax (%)',
                    prefixIcon: Icon(Icons.receipt),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveProduct,
                  child: const Text(
                    'Save Product',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
